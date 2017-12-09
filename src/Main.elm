module Main exposing (..)

import Html exposing (Html, text, div, img, a, span, ul, li, input, button)
import Html.Attributes exposing (placeholder, id, style, href, src, title)
import Html.Events exposing (onInput, onClick)
import Json.Decode exposing (string, list, Decoder)
import Json.Decode.Pipeline exposing (decode, required)
import Regex
import Http
import Task
import Dom


dataUrl =
  "./data/index.json"


main : Program Never Model Msg
main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }



-- MODEL


type ViewMode
  = Text
  | Thumbnails
  | ThumbnailsWithTitle


type alias Items =
  List Item


type alias LoadStatus =
  Maybe Http.Error

type alias Model =
  { searchStr : String
  , maybeItems : Maybe Items
  , viewMode : ViewMode
  , loadStatus : LoadStatus
  }


init : ( Model, Cmd Msg )
init =
  ( Model "" Nothing Text Nothing
  , getItemData
  )


type alias Item =
  { id : String
  , title : String
  }


itemDecoder : Decoder Item
itemDecoder =
  decode Item
    |> required "id" string
    |> required "title" string


itemsDecoder : Decoder (List Item)
itemsDecoder =
  list itemDecoder



-- UPDATE


type Msg
  = NoOp
  | Change String
  | SetViewText
  | SetViewThumbnails
  | SetViewThumbnailsWithTitle
  | DataLoaded (Result Http.Error Items)


getItemData : Cmd Msg
getItemData =
  Http.send DataLoaded (Http.get dataUrl itemsDecoder)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    NoOp ->
      ( model, Cmd.none )

    Change newContent ->
      ( { model | searchStr = newContent }, Cmd.none )

    SetViewText ->
      ( { model | viewMode = Text }, Cmd.none )

    SetViewThumbnails ->
      ( { model | viewMode = Thumbnails }, Cmd.none )

    SetViewThumbnailsWithTitle ->
      ( { model | viewMode = ThumbnailsWithTitle }, Cmd.none )

    DataLoaded (Ok newItems) ->
      ( { model | maybeItems = Just newItems }, Task.attempt (\_ -> NoOp) (Dom.focus "search") )

    DataLoaded (Err httpError) ->
      ( { model | loadStatus = Just httpError }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- VIEW


type alias StyleList =
  List ( String, String )


view : Model -> Html Msg
view model =
  div []
    [ viewSearchField model.loadStatus model.searchStr model.maybeItems
    , viewModeControls model.viewMode
    , viewItems model.loadStatus model.searchStr model.maybeItems model.viewMode
    ]


viewSearchField : LoadStatus -> String -> Maybe Items -> Html Msg
viewSearchField loadStatus searchStr maybeItems =
  div []
    [ input [ id "search", placeholder "Search...", onInput Change ] []
    , viewSearchStats loadStatus searchStr maybeItems
    ]


viewSearchStats : LoadStatus -> String -> Maybe Items -> Html Msg
viewSearchStats loadStatus searchStr maybeItems =
  let
    message =
      case maybeItems of
        Nothing ->
          case loadStatus of
            Nothing ->
              "loading..."

            Just _ ->
              "failed to load data"

        Just items ->
          let
            count =
              List.length (filteredItems searchStr items)
          in
            toString count ++ " pages"
  in
    span [] [ text <| " (" ++ message ++ ")" ]


viewModeControls : ViewMode -> Html Msg
viewModeControls viewMode =
  div [ style [ ( "display", "inline-block" ), ( "margin-top", "6px" ), ( "margin-bottom", "4px" ) ] ]
    [ viewModeButton viewMode Text
    , viewModeButton viewMode Thumbnails
    , viewModeButton viewMode ThumbnailsWithTitle
    ]


viewModeButton : ViewMode -> ViewMode -> Html Msg
viewModeButton currentMode setsMode =
  let
    baseStyle =
      [ ( "height", "22px" )
      , ( "margin-right", "4px" )
      , ( "background-color", "white" )
      , ( "color", "#666" )
      ]

    activeStyle =
      [ ( "color", "black" )
      , ( "background-color", "darkgrey" )
      , ( "border", "2px solid black" )
      ]

    buttonStyle =
      if setsMode == currentMode then
        List.append baseStyle activeStyle
      else
        baseStyle

    ( eventMsg, caption ) =
      case setsMode of
        Text ->
          ( SetViewText, "title" )

        Thumbnails ->
          ( SetViewThumbnails, "image" )

        ThumbnailsWithTitle ->
          ( SetViewThumbnailsWithTitle, "image and title" )

  in
    button [ style buttonStyle, onClick eventMsg ] [ text caption ]


viewItems : LoadStatus -> String -> Maybe Items -> ViewMode -> Html Msg
viewItems loadStatus searchStr maybeItems viewMode =
  case maybeItems of
    Nothing ->
      case loadStatus of
        Nothing ->
          div [] [ text "Loading..." ]

        Just httpError ->
          div [ style [ ( "color", "red" ) ] ] [ text <| "HTTP Error: " ++ (httpErrorString httpError) ]

    Just items ->
      ul
        [ style
            [ ( "margin", "0" )
            , ( "padding", "0" )
            ]
        ]
        (List.map (viewItem viewMode) (filteredItems searchStr items))


itemFilter : String -> Item -> Bool
itemFilter searchStr item =
  Regex.contains ((Regex.regex >> Regex.caseInsensitive) searchStr) item.title


filteredItems : String -> Items -> Items
filteredItems searchStr items =
  List.filter (itemFilter searchStr) items


pageLink : String -> String
pageLink id =
  "https://www.facebook.com/" ++ id


viewThumbnail : String -> String -> StyleList -> Html Msg
viewThumbnail id hoverTip styles =
  a
    [ href <| pageLink id, style styles ]
    [ img [ src ("./data/images/" ++ id), title hoverTip ] [] ]


viewItem : ViewMode -> Item -> Html Msg
viewItem viewMode item =
  let
    listStyle =
      [ ( "list-style-type", "none" )
      , ( "display", "inline-block" )
      ]

    linkStyle =
      [ ( "margin", "auto" )
      , ( "margin-left", "0" )
      , ( "text-decoration", "none" )
      ]
  in
    case viewMode of
      Text ->
        li
          []
          [ a [ href <| pageLink item.id ] [ text item.title ] ]

      Thumbnails ->
        li
          [ style listStyle ]
          [ viewThumbnail item.id item.title [] ]

      ThumbnailsWithTitle ->
        li
          [ style <| List.append listStyle [ ( "display", "flex" ) ] ]
          [ viewThumbnail item.id "" [ ( "margin-right", "8px" ) ]
          , a [ href <| pageLink item.id, style linkStyle ]
              [ text item.title ]
          ]



-- HELPERS


httpErrorString : Http.Error -> String
httpErrorString httpError =
  case httpError of
    Http.BadUrl url ->
      "Bad URL: " ++ url

    Http.Timeout ->
      "Request timed out"

    Http.NetworkError ->
      "Network error"

    Http.BadStatus response ->
      toString response.status.code ++ " (" ++ response.status.message ++ ")"

    Http.BadPayload explanation response ->
      "Bad payload: " ++ explanation
