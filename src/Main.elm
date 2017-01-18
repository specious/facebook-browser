module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (placeholder)
import Html.Events exposing (onInput)


-- # Main


main : Program Never Model Msg
main =
  Html.beginnerProgram
    { model = model
    , view = view
    , update = update
    }



-- # Model


type alias Model =
  String


model : Model
model =
  ""



-- # Messages


type Msg
  = Change String



-- # Update


update : Msg -> Model -> Model
update msg model =
  case msg of
    Change newContent ->
      newContent



-- # View


view : Model -> Html Msg
view model =
  input [ placeholder "Search...", onInput Change ] []
