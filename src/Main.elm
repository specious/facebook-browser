module Main exposing (..)

import Html exposing (Html, text, div, img, a, span, h3, ul, li, input, button)
import Html.Attributes exposing (placeholder, id, style, href, src)
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


type alias Model =
  { searchStr : String
  , maybeItems : Maybe Items
  , viewMode : ViewMode
  }


init : ( Model, Cmd Msg )
init =
  ( Model "" Nothing Text
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

    DataLoaded (Err _) ->
      ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ input [ id "search", placeholder "Search...", onInput Change ] []
    , viewModeButtons
    , viewItems model.searchStr model.maybeItems model.viewMode
    ]


viewModeButtons : Html Msg
viewModeButtons =
  let
    glyphColor =
      "#666"

    buttonStyle =
      [ ( "width", "22px" )
      , ( "height", "22px" )
      , ( "padding-left", "0" )
      , ( "padding-right", "0" )
      , ( "margin-left", "4px" )
      , ( "background-color", "white" )
      , ( "color", glyphColor )
      ]

    textViewButtonStyle =
      List.append buttonStyle
        [ ( "font-style", "italic" ) ]
  in
    div [ style [ ( "display", "inline-block" ) ] ]
      [ button [ style textViewButtonStyle, onClick SetViewText ] [ text "A" ]
      , button [ style buttonStyle, onClick SetViewThumbnails ] [ text "⦁" ]
      , button [ style buttonStyle, onClick SetViewThumbnailsWithTitle ] [ text "≡" ]
      ]


viewItems : String -> Maybe Items -> ViewMode -> Html Msg
viewItems searchStr maybeItems viewMode =
  case maybeItems of
    Nothing ->
      div [] [ text "Loading..." ]

    Just items ->
      let
        filteredItems =
          List.filter (itemFilter searchStr) items
      in
        ul [ style [ ( "padding", "0" ) ] ] (List.map (viewItem viewMode) filteredItems)


itemFilter searchStr item =
  Regex.contains ((Regex.regex >> Regex.caseInsensitive) searchStr) item.title


viewItem : ViewMode -> Item -> Html Msg
viewItem viewMode item =
  case viewMode of
    Text ->
      li
        []
        [ a [ href ("https://www.facebook.com/" ++ item.id) ] [ text item.title ] ]

    _ ->
      viewItemWithThumbnail viewMode item


viewThumbnail id styles =
  a
    [ href ("https://www.facebook.com/" ++ id)
    , style styles
    ]
    [ img [ src ("./data/images/" ++ id) ] [] ]


viewItemWithThumbnail viewMode item =
  let
    listStyle =
      [ ( "list-style-type", "none" )
      , ( "display", "inline-block" )
      ]

    linkStyle =
      [ ( "margin", "auto" )
      , ( "margin-left", "0" )
      , ( "color", "blue" )
      ]
  in
    case viewMode of
      Thumbnails ->
        li
          [ style listStyle ]
          [ viewThumbnail item.id [] ]

      ThumbnailsWithTitle ->
        li
          [ style <| List.append listStyle [ ( "display", "flex" ) ] ]
          [ viewThumbnail item.id [ ( "margin-right", "8px" ) ]
          , h3
              [ style linkStyle ]
              [ text item.title ]
          ]

      _ ->
        div [] [ text "Should never happen" ]
