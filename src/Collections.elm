module Collections exposing (init, main, update, view)

import Browser
import Css exposing (..)
import Css.Animations
import Css.Global
import Dict
import Html.Styled exposing (Html, button, div, img, li, text, toUnstyled, ul)
import Html.Styled.Attributes as Attributes exposing (alt, class, css, src, style)
import Html.Styled.Events exposing (onClick)
import Http exposing (header)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as DecodePipeline
import Json.Encode as Encode
import Url.Builder


apiUrl : String
apiUrl =
    "https://api.unsplash.com/"



-- Model


type alias User =
    { id : String
    , username : String
    , name : String
    }


type alias Urls =
    { small : String
    , raw : String
    }


type alias Photo =
    { id : String
    , width : Int
    , height : Int
    , color : String
    , description : Maybe String
    , user : User
    , urls : Urls
    }


type Order
    = Latest
    | Oldest
    | Popular


orderToString : Order -> String
orderToString order =
    case order of
        Latest ->
            "latest"

        Oldest ->
            "oldest"

        Popular ->
            "popular"


type alias Pagination =
    { nextPage : Int
    , perPage : Int
    , orderBy : Order
    , hasMore : Bool
    }


type alias PhotoResponse =
    { photos : List Photo
    , perPage : Int
    , total : Int
    }


type alias Model =
    { selectedPhotoUrl : Maybe String
    , photos : List Photo
    , isLoading : Bool
    , accessKey : String
    , pagination : Pagination
    , error : Maybe String
    }


initialModel : Model
initialModel =
    { selectedPhotoUrl = Nothing
    , photos = []
    , isLoading = True
    , accessKey = ""
    , pagination = { nextPage = 1, perPage = 30, orderBy = Latest, hasMore = Basics.True }
    , error = Nothing
    }


init : String -> ( Model, Cmd Msg )
init flags =
    ( { initialModel | accessKey = flags }
    , fetchPhotos flags initialModel.pagination
    )


type Msg
    = GotPhotos (Result Http.Error PhotoResponse)
    | LoadMore



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotPhotos (Ok response) ->
            ( { model
                | photos = model.photos ++ response.photos
                , pagination = updatePagination model.pagination
                , isLoading = False
              }
            , Cmd.none
            )

        -- TODO: Handle the error
        GotPhotos (Err err) ->
            ( { model | isLoading = False, error = errorToString err }, Cmd.none )

        LoadMore ->
            ( { model | isLoading = True, error = Nothing }, fetchPhotos model.accessKey model.pagination )


errorToString : Http.Error -> Maybe String
errorToString error =
    let
        err = case error of
            Http.BadUrl url ->
                "The URL " ++ url ++ " was invalid"
            Http.Timeout ->
                "Unable to reach the server, try again"
            Http.NetworkError ->
                "Unable to reach the server, check your network connection"
            Http.BadStatus 500 ->
                "The server had a problem, try again later"
            Http.BadStatus 400 ->
                "Verify your information and try again"
            Http.BadStatus _ ->
                "Unknown error"
            Http.BadBody errorMessage ->
                errorMessage
    in
    Just err

-- TODO: Calculate next page based on per_page and total.
-- TODO: If there are no more photos, set `hasMore` to False


updatePagination : Pagination -> Pagination
updatePagination pagination =
    { pagination | nextPage = pagination.nextPage + 1 }



-- View


globalStylesNode : Html msg
globalStylesNode =
    Css.Global.global
        [ Css.Global.everything [ boxSizing borderBox ]
        , Css.Global.ul [ margin (px 0), padding (px 0), listStyle none ]
        , Css.Global.body
            [ fontFamilies [ "sans-serif" ]
            , fontSize (px 16)
            , color (hex "#484848")
            , margin (px 0)
            ]
        ]


view : Model -> Html Msg
view model =
    div
        [ class "collections" ]
        [ globalStylesNode
        , ul
            [ css
                [ displayFlex
                , flexWrap wrap
                , after [ flexGrow (Css.int 9999), property "content" "''" ]
                ]
            ]
          <|
            List.map viewPhoto model.photos
        , viewLoadingSpinner model.isLoading
        , viewTemporaryButton
        , viewError model.error
        ]

viewError : Maybe String -> Html Msg
viewError error =
    case error of
        Just err -> 
            text err
        Nothing ->
                text ""

viewLoadingSpinner : Bool -> Html Msg
viewLoadingSpinner isLoading =
    let
        spinningAnimation =
            Css.Animations.keyframes
                [ ( 0, [ Css.Animations.transform [ rotate (deg 0) ] ] )
                , ( 100, [ Css.Animations.transform [ rotate (deg 360) ] ] )
                ]
    in
    if isLoading then
        div
            [ css
                [ position fixed
                , zIndex (int 1)
                , right (em 2)
                , bottom (em 2)
                , width (px 48)
                , height (px 48)
                , borderRadius (px 96)
                , border3 (px 2) solid (hex "000")
                , borderTopColor transparent
                , animationName spinningAnimation
                , animationDuration (sec 1)
                , property "animation-iteration-count" "infinite"
                , property "animation-timing-function" "linear"
                ]
            ]
            []

    else
        text ""


viewTemporaryButton : Html Msg
viewTemporaryButton =
    div
        [ css
            [ displayFlex
            , alignItems center
            , justifyContent center
            , padding2 (px 16) zero
            ]
        ]
        [ button
            [ css
                [ padding2 (px 8) (px 12)
                , border3 (px 1) solid (hex "fc0")
                , backgroundColor (hex "fff")
                , fontSize (rem 1.3)
                ]
            , onClick LoadMore
            , Attributes.attribute "data-button" "load-more"
            ]
            [ text "Загрузить еще" ]
        ]


viewPhoto : Photo -> Html Msg
viewPhoto photo =
    let
        ratio =
            toFloat photo.width / toFloat photo.height

        calculatedWidth : Int
        calculatedWidth =
            Basics.ceiling (ratio * 250)

        description =
            case photo.description of
                Just text ->
                    text

                Nothing ->
                    ""
    in
    li
        [ style "flex-grow" (String.fromInt calculatedWidth)
        , style "flex-basis" (String.fromInt calculatedWidth ++ "px")
        , css [ margin (px 1.5) ]
        ]
        [ img
            [ css
                [ display block
                , width (pct 100)
                , height (pct 100)
                , property "object-fit" "cover"
                ]
            , alt description
            , src photo.urls.small
            , Attributes.width calculatedWidth
            , Attributes.attribute "loading" "lazy"
            , Attributes.attribute "data-image-id" photo.id
            ]
            []
        ]



-- Decoders and Http


fetchPhotos : String -> Pagination -> Cmd Msg
fetchPhotos accessKey pagination =
    let
        headers =
            [ header "Authorization" ("Client-ID " ++ accessKey) ]

        url =
            Url.Builder.relative
                [ apiUrl, "photos" ]
                [ Url.Builder.int "per_page" pagination.perPage
                , Url.Builder.int "page" pagination.nextPage
                ]
    in
    getPhotos url headers


getPhotos : String -> List Http.Header -> Cmd Msg
getPhotos url headers =
    Http.request
        { method = "GET"
        , headers = headers
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectStringResponse GotPhotos extractPhotosResponse
        , timeout = Nothing
        , tracker = Nothing
        }


extractPhotosResponse : Http.Response String -> Result Http.Error PhotoResponse
extractPhotosResponse response =
    case response of
        Http.GoodStatus_ metadata json ->
            let
                total =
                    Dict.get "x-total" metadata.headers
                        |> Maybe.andThen String.toInt
                        |> Maybe.withDefault 0

                perPage =
                    Dict.get "x-per-page" metadata.headers
                        |> Maybe.andThen String.toInt
                        |> Maybe.withDefault 30
            in
            case Decode.decodeString photosDecoder json of
                Ok photos ->
                    Ok { perPage = perPage, total = total, photos = photos }

                Err err ->
                    Err (Http.BadBody (Decode.errorToString err))

        Http.BadStatus_ metadata _ ->
            Err (Http.BadStatus metadata.statusCode)

        Http.BadUrl_ url ->
            Err (Http.BadUrl url)

        Http.Timeout_ ->
            Err Http.Timeout

        Http.NetworkError_ ->
            Err Http.NetworkError


photosDecoder : Decoder (List Photo)
photosDecoder =
    Decode.list photoDecoder


photoDecoder : Decoder Photo
photoDecoder =
    Decode.succeed Photo
        |> DecodePipeline.required "id" Decode.string
        |> DecodePipeline.required "width" Decode.int
        |> DecodePipeline.required "height" Decode.int
        |> DecodePipeline.required "color" Decode.string
        |> DecodePipeline.required "description" (Decode.nullable Decode.string)
        |> DecodePipeline.required "user" userDecoder
        |> DecodePipeline.required "urls" urlsDecoder


urlsDecoder : Decoder Urls
urlsDecoder =
    Decode.succeed Urls
        |> DecodePipeline.required "small" Decode.string
        |> DecodePipeline.required "raw" Decode.string


userDecoder : Decoder User
userDecoder =
    Decode.succeed User
        |> DecodePipeline.required "id" Decode.string
        |> DecodePipeline.required "username" Decode.string
        |> DecodePipeline.required "name" Decode.string



-- Main


main : Program String Model Msg
main =
    Browser.element
        { init = init
        , view = view >> toUnstyled
        , update = update
        , subscriptions = \_ -> Sub.none
        }
