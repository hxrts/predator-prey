module Main where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Console (log)
import Web.DOM.Element (toNode)
import Web.DOM.Node (setTextContent)
import Web.DOM.NonElementParentNode (getElementById)
import Web.HTML (window)
import Web.HTML.HTMLDocument (toNonElementParentNode)
import Web.HTML.Window (document)

main :: Effect Unit
main = do
  log "Hello from PureScript!"
  
  -- Get the window and document
  w <- window
  doc <- document w
  
  -- Try to get the app element
  appElement <- getElementById "app" (toNonElementParentNode doc)
  case appElement of
    Just element -> do
      setTextContent "Hello World!" (toNode element)
    Nothing -> 
      log "Could not find app element" 