module Collections exposing (init, main, update, view)

import Browser
import Css exposing (..)
import Css.Global
import Html.Styled exposing (Html, div, img, li, toUnstyled, ul)
import Html.Styled.Attributes exposing (alt, class, css, src, style)
import Http exposing (header)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as DecodePipeline
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
    { page : Int
    , per_page : Int
    , order_by : Order
    }


type alias Model =
    { selectedPhotoUrl : Maybe String
    , photos : List Photo
    , accessKey : String
    , pagination : Pagination
    }


initialModel : Model
initialModel =
    { selectedPhotoUrl = Nothing
    , photos = []
    , accessKey = ""
    , pagination = { page = 1, per_page = 40, order_by = Latest }
    }


init : String -> ( Model, Cmd Msg )
init flags =
    ( { initialModel | accessKey = flags }
    , fetchPhotos flags initialModel.pagination
    )


type Msg
    = GotPhotos (Result Http.Error (List Photo))



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotPhotos (Ok photos) ->
            ( { model | photos = photos }, Cmd.none )

        -- TODO: Handle the error
        GotPhotos (Err _) ->
            ( model, Cmd.none )



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
            List.map viewImage model.photos
        ]


viewImage : Photo -> Html Msg
viewImage photo =
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
            [ css [ display block, width (pct 100), property "object-fit" "cover" ]
            , alt description
            , src photo.urls.small
            ]
            []
        ]



-- Decoders and Http


fetchPhotos : String -> Pagination -> Cmd Msg
fetchPhotos accessKey pagination =
    let
        headers =
            [ header "Authorization" ("Client-ID " ++ accessKey) ]

        -- TODO: Add `page` parameter
        url =
            Url.Builder.relative [ apiUrl, "photos" ] [ Url.Builder.int "per_page" pagination.per_page ]
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson GotPhotos photosDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


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
