module Main exposing (..)

import Html exposing (Html, text, div, img, a, span, h3, ul, li, input, button)
import Html.Attributes exposing (placeholder, id, style, href, src)
import Html.Events exposing (onInput, onClick)
import Json.Decode exposing (string, list, Decoder)
import Json.Decode.Pipeline exposing (decode, required, hardcoded)
import Regex
import Http
import Task
import Dom


dataUrl =
  "./data/index.json"



-- # Main


main : Program Never Model Msg
main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }



-- # Model


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
  ( Model "" Nothing Thumbnails
  , getItemData
  )


type alias Item =
  { id : String
  , title : String
  , hidden : Bool
  }


itemDecoder : Decoder Item
itemDecoder =
  decode Item
    |> required "id" string
    |> required "title" string
    |> hardcoded False


itemsDecoder : Decoder (List Item)
itemsDecoder =
  list itemDecoder



-- # Update


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



-- # Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- # View


view : Model -> Html Msg
view model =
  div []
    [ input [ id "search", placeholder "Search...", onInput Change ] []
    , button [ onClick SetViewText ] [ text "Title" ]
    , button [ onClick SetViewThumbnails ] [ text "Thumb" ]
    , button [ onClick SetViewThumbnailsWithTitle ] [ text "Thumb + Title" ]
    , viewItems model.searchStr model.maybeItems model.viewMode
    ]


viewItems : String -> Maybe Items -> ViewMode -> Html Msg
viewItems searchStr maybeItems viewMode =
  case maybeItems of
    Nothing ->
      div [] [ text "Loading..." ]

    Just items ->
      let
        filteredItems =
          List.map (\item -> { item | hidden = itemFilter searchStr item }) items
      in
        ul [] (List.map (viewItem viewMode) filteredItems)


itemFilter searchStr item =
  not <| Regex.contains ((Regex.regex >> Regex.caseInsensitive) searchStr) item.title


viewItem : ViewMode -> Item -> Html Msg
viewItem viewMode item =
  let
    cullStyle =
      case item.hidden of
        True ->
          [ ( "display", "none" ) ]

        False ->
          []
  in
    case viewMode of
      Text ->
        li
          [ style cullStyle ]
          [ a [ href ("https://www.facebook.com/" ++ item.id) ] [ text item.title ] ]

      _ ->
        viewItemWithThumbnail viewMode cullStyle item


viewThumbnail id styles =
  a
    [ href ("https://www.facebook.com/" ++ id)
    , style styles
    ]
    [ img [ src ("./data/images/" ++ id) ] [] ]


viewItemWithThumbnail viewMode extraStyle item =
  let
    listStyle =
      [ ( "list-style-type", "none" ) ]
  in
    case viewMode of
      Thumbnails ->
        li
          [ style <|
              List.foldr List.append
                listStyle
                [ [ ( "display", "inline-block" ) ], extraStyle ]
          ]
          [ viewThumbnail item.id [] ]

      ThumbnailsWithTitle ->
        li
          [ style <|
              List.foldr List.append
                listStyle
                [ [ ( "display", "flex" ) ], extraStyle ]
          ]
          [ viewThumbnail item.id [ ( "margin-right", "8px" ) ]
          , h3
              [ style
                  [ ( "margin", "auto" )
                  , ( "margin-left", "0" )
                  , ( "color", "blue" )
                  ]
              ]
              [ text item.title ]
          ]

      _ ->
        div [] [ text "Should never happen" ]
