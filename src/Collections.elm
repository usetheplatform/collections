module Collections exposing (init, main, update, view)

import Browser
import Dict
import Html exposing (Attribute, Html, button, div, h2, img, li, p, text, ul)
import Html.Attributes as Attributes exposing (alt, attribute, class, id, src, style)
import Html.Events exposing (onClick, onFocus, onMouseOver)
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


type alias ScreenData =
    { scrollTop : Int
    , viewportHeight : Int
    }


type alias Model =
    { selectedPhotoId : Maybe String
    , photos : List Photo
    , isLoading : Bool
    , accessKey : String
    , pagination : Pagination
    , error : Maybe String
    }


initialModel : Model
initialModel =
    { selectedPhotoId = Nothing
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
    | ShouldLoadMore Bool
    | SelectPhoto String
    | CloseDialog



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

        ShouldLoadMore shouldLoadMore ->
            -- TODO: When loading time is too big, sometimes it fires redundant request.
            if shouldLoadMore && not model.isLoading then
                ( { model | isLoading = True, error = Nothing }, fetchPhotos model.accessKey model.pagination )

            else
                ( model, Cmd.none )

        SelectPhoto id ->
            ( { model | selectedPhotoId = Just id }, Cmd.none )

        CloseDialog ->
            ( { model | selectedPhotoId = Nothing }, Cmd.none )


errorToString : Http.Error -> Maybe String
errorToString error =
    let
        err =
            case error of
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
-- TODO: Добавить Html.keyed для рендера списка


view : Model -> Html Msg
view model =
    div
        [ class "collections" ]
        ([ ul [ class "gallery" ] <|
            List.map viewPhoto model.photos
         , scrollListener [ onIntersected ShouldLoadMore ] []
         , viewLoadingSpinner model.isLoading
         , viewTemporaryButton model.isLoading
         , viewError model.error
         ]
            ++ viewSelectedPhoto model.selectedPhotoId model.photos
        )



-- TODO: Design error


viewError : Maybe String -> Html Msg
viewError error =
    case error of
        Just err ->
            text err

        Nothing ->
            text ""


viewLoadingSpinner : Bool -> Html Msg
viewLoadingSpinner isLoading =
    if isLoading then
        div [ class "spinner" ] []

    else
        text ""


viewTemporaryButton : Bool -> Html Msg
viewTemporaryButton isLoading =
    div
        [ class "loading-indicator", Attributes.disabled isLoading ]
        [ button
            [ class "loading-indicator__text"
            , onClick LoadMore
            , attribute "data-button" "load-more"
            ]
            [ text
                (if isLoading then
                    "Загружаем..."

                 else
                    "Загрузить еще"
                )
            ]
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
        [ style "flex-basis" (String.fromInt calculatedWidth ++ "px")
        , style "background-color" photo.color
        , class "gallery__item"
        ]
        [ imageLoader
            [ attribute "color" photo.color
            , attribute "id" photo.id
            , alt description
            , src photo.urls.small

            -- TODO: onClick should belong to button
            , onClick (SelectPhoto photo.id)
            ]
            []
        ]



-- TODO: Передавать сюда онклик и другие параметры если надо


viewButton : Html Msg
viewButton =
    button [ class "carousel__arrow" ] []



{-
   TODO: Подумать как лучше организовать поиск фотографий в списке @see PhotoGrove app
   TODO: Доделать диалоговое окно @see https://www.w3.org/TR/wai-aria-practices/examples/dialog-modal/dialog.html
   TODO: Сделать фокус
   TODO: Handle keyboard events
   TODO: Добавить Html.keyed
   Это какой-то пиздец, нужно все переделать. Код очень плохой

   Переключение можно сделать через тот же `SelectPhoto photo.id`

   viewCarousel
   viewCarourselItem
   viewDialog
-}


findBy : (a -> Bool) -> List a -> Maybe a
findBy fun list =
    List.head (List.filter fun list)


viewDialog : String -> Msg -> Html Msg -> List (Html Msg)
viewDialog title closeMsg content =
    [ div [ class "dialog__backdrop" ] []
    , div
        [ class "dialog"
        , attribute "role" "dialog"
        , id "selected-photo-dialog"
        , attribute "aria-labelledby" "selected-photo-dialog_label"
        , attribute "aria-modal" "true"
        ]
        [ h2
            [ class "sr-only", id "selected-photo-dialog_label" ]
            [ text title ]
        , button [ onClick closeMsg, class "button--close" ] []
        , content
        ]
    ]



-- TODO: Make image-loader custom element


viewSelectedPhoto : Maybe String -> List Photo -> List (Html Msg)
viewSelectedPhoto photoId photos =
    case photoId of
        Just id ->
            let
                -- TODO: И как теперь найти тех кто рядом? Посмотреть PhotoGroove на предмет замены findBy!
                currentPhoto =
                    findBy (\photo -> photo.id == id) photos

                prevPhoto =
                    Nothing

                nextPhoto =
                    Nothing

                -- TODO: Find a way to apply image-loader to carousel image too
                -- TODO: Detect window sizes and load only appropriate image size (@see picture tag)
                viewCarouselItem photo =
                    li
                        [ class "carousel__item" ]
                        [ img
                            [ class "carousel__image"
                            , style "background-color" photo.color
                            , attribute "data-image-id" photo.id
                            , src photo.urls.raw
                            ]
                            []
                        ]

                viewCarousel =
                    ul [ class "carousel" ] <|
                        case ( currentPhoto, prevPhoto, nextPhoto ) of
                            ( Nothing, _, _ ) ->
                                [ text "" ]

                            -- TODO: Как теперь передать им информацию о том какой из них кто?
                            ( Just photo, Nothing, Nothing ) ->
                                [ viewCarouselItem photo ]

                            ( Just photo, Just prev, Just next ) ->
                                [ viewButton, viewCarouselItem prev, viewCarouselItem photo, viewCarouselItem next, viewButton ]

                            ( Just photo, Just prev, Nothing ) ->
                                [ viewButton, viewCarouselItem prev, viewCarouselItem photo ]

                            ( Just photo, Nothing, Just next ) ->
                                [ viewCarouselItem photo, viewCarouselItem next, viewButton ]
            in
            viewDialog "Dialog title" CloseDialog viewCarousel

        Nothing ->
            [ text "" ]


scrollListener : List (Attribute msg) -> List (Html msg) -> Html msg
scrollListener attributes children =
    Html.node "scroll-listener" attributes children


imageLoader : List (Attribute msg) -> List (Html msg) -> Html msg
imageLoader attributes children =
    Html.node "image-loader" attributes children


onIntersected : (Bool -> msg) -> Attribute msg
onIntersected toMsg =
    Decode.at [ "detail" ] Decode.bool
        |> Decode.map toMsg
        |> Html.Events.on "intersected"



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
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
