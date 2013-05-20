{-# LANGUAGE CPP, PackageImports #-}
{-# LANGUAGE TypeSynonymInstances, FlexibleInstances #-}

import Prelude hiding (div,span)
import Control.Applicative
import Control.Monad
import Data.IORef
import Data.Maybe

import Paths
import qualified Data.List as L (drop)
#ifdef CABAL
import "threepenny-gui" Graphics.UI.Threepenny
#else
import Graphics.UI.Threepenny
#endif

-- | Main entry point. Starts a TP server.
main :: IO ()
main = do
    static <- getStaticDir
    startGUI Config
        { tpPort       = 10000
        , tpCustomHTML = Nothing
        , tpStatic     = static
        } setup

setup :: Window -> IO ()
setup w = do
    -- active elements
    return w # set title "BarTab"

    elAdd    <- button w # set text "Add"
    elRemove <- button w # set text "Remove"
    elResult <- span      w

    inputs   <- newIORef []
    
    -- functionality
    let
        displayTotal = do
            is <- readIORef inputs
            xs <- getValuesList is
            element elResult # set text (showNumber . sum $ map readNumber xs)
            return ()

        mkInput :: IO ()
        mkInput = do
            elInput <- input w
            on blur elInput $ \_ -> displayTotal
            is      <- readIORef inputs
            writeIORef inputs $ elInput : is
            redoLayout
        
        mkRemove :: IO ()
        mkRemove = do
            is      <- readIORef inputs
            let n = L.drop 1 is
            writeIORef inputs $ n
            redoLayout
            displayTotal

        redoLayout :: IO ()
        redoLayout = do
            layout <- mkLayout =<< readIORef inputs
            getBody w # set children [layout]
            return ()
        
        mkLayout :: [Element] -> IO Element
        mkLayout xs = column $
            [row [element elAdd, element elRemove]
            ,hr w]
            ++ map element xs ++
            [hr w
            ,row [span w # set text "Sum: ", element elResult]
            ]
        
    on click elAdd $ \_ -> mkInput
    mkInput
    on click elRemove $ \_ -> mkRemove


{-----------------------------------------------------------------------------
    Functionality
------------------------------------------------------------------------------}
type Number = Maybe Double

instance Num Number where
    (+) = liftA2 (+)
    (-) = liftA2 (-)
    (*) = liftA2 (*)
    abs = fmap abs
    signum = fmap signum
    fromInteger = pure . fromInteger

readNumber :: String -> Number
readNumber s = listToMaybe [x | (x,"") <- reads s]    
showNumber   = maybe "--" show
