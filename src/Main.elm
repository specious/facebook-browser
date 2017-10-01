module Main exposing (..)

import Html exposing (Html, text, div, img, a, span, h3, ul, li, input, button)
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


type alias StyleList =
  List ( String, String )


view : Model -> Html Msg
view model =
  div []
    [ viewSearchField model.searchStr model.maybeItems
    , viewModeControls
    , viewItems model.searchStr model.maybeItems model.viewMode
    ]


viewSearchField : String -> Maybe Items -> Html Msg
viewSearchField searchStr maybeItems =
  div []
    [ input [ id "search", placeholder "Search...", onInput Change ] []
    , viewSearchStats searchStr maybeItems
    ]


viewSearchStats : String -> Maybe Items -> Html Msg
viewSearchStats searchStr maybeItems =
  case maybeItems of
    Nothing ->
      span [] [ text " (loading...)" ]

    Just items ->
      let
        count =
          List.length (filteredItems searchStr items)
      in
        span [] [ text <| " (" ++ toString count ++ " pages)" ]


viewModeControls : Html Msg
viewModeControls =
  let
    buttonStyle =
      [ ( "height", "22px" )
      , ( "margin-right", "4px" )
      , ( "background-color", "white" )
      , ( "color", "#666" )
      ]
  in
    div [ style [ ( "display", "inline-block" ), ( "margin-top", "6px" ), ( "margin-bottom", "4px" ) ] ]
      [ button [ style buttonStyle, onClick SetViewText ] [ text "title" ]
      , button [ style buttonStyle, onClick SetViewThumbnails ] [ text "image" ]
      , button [ style buttonStyle, onClick SetViewThumbnailsWithTitle ] [ text "image and title" ]
      ]


viewItems : String -> Maybe Items -> ViewMode -> Html Msg
viewItems searchStr maybeItems viewMode =
  case maybeItems of
    Nothing ->
      div [] [ text "Loading..." ]

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


viewItem : ViewMode -> Item -> Html Msg
viewItem viewMode item =
  case viewMode of
    Text ->
      li
        []
        [ a [ href ("https://www.facebook.com/" ++ item.id) ] [ text item.title ] ]

    _ ->
      viewItemWithThumbnail viewMode item


viewThumbnail : String -> String -> StyleList -> Html Msg
viewThumbnail id hoverTip styles =
  a
    [ href ("https://www.facebook.com/" ++ id)
    , style styles
    ]
    [ img [ src ("./data/images/" ++ id), title hoverTip ] [] ]


viewItemWithThumbnail : ViewMode -> Item -> Html Msg
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
          [ viewThumbnail item.id item.title [] ]

      ThumbnailsWithTitle ->
        li
          [ style <| List.append listStyle [ ( "display", "flex" ) ] ]
          [ viewThumbnail item.id "" [ ( "margin-right", "8px" ) ]
          , h3
              [ style linkStyle ]
              [ text item.title ]
          ]

      _ ->
        div [] [ text "Should never happen" ]
