module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (placeholder, href)
import Html.Events exposing (onInput)
import Json.Decode exposing (string, list, Decoder)
import Json.Decode.Pipeline exposing (decode, required)
import Regex
import Http


dataUrl = "./data/index.json"

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

type alias Items = List Item


type alias Model =
  { searchStr : String
  , maybeItems : Maybe Items
  }


init : (Model, Cmd Msg)
init =
  ( Model "" Nothing
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

-- # Update


type Msg
  = Change String
  | DataLoaded (Result Http.Error Items)


getItemData : Cmd Msg
getItemData =
  Http.send DataLoaded (Http.get dataUrl itemsDecoder)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Change newContent ->
      ({ model | searchStr = newContent }, Cmd.none)

    DataLoaded (Ok newItems) ->
      ({ model | maybeItems = Just newItems }, Cmd.none)

    DataLoaded (Err _) ->
      (model, Cmd.none)


-- # Subscriptions

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


-- # View


view : Model -> Html Msg
view model =
  div []
    [ input [ placeholder "Search...", onInput Change ] []
    , viewItems model.searchStr model.maybeItems
    ]

viewItems : String -> Maybe Items -> Html Msg
viewItems searchStr maybeItems =
  case maybeItems of
    Nothing ->
      div [] [ text "Loading..." ]
    Just items ->
      let
        filteredItems = List.filter (itemFilter searchStr) items
      in
        ul [] (List.map viewItem filteredItems)

itemFilter searchStr item =
  Regex.contains ((Regex.regex >> Regex.caseInsensitive) searchStr) item.title

viewItem : Item -> Html Msg
viewItem item =
  li []
   [ a [ href ("https://www.facebook.com/" ++ item.id) ] [ text item.title ] ]
