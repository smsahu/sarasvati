{-
    This file is part of Sarasvati.

    Sarasvati is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    Sarasvati is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public 
    License along with Sarasvati.  If not, see <http://www.gnu.org/licenses/>.

    Copyright 2008 Paul Lorenz
-}


module Workflow.Util.XmlUtil where

import Text.XML.HaXml.Combinators
import Text.XML.HaXml.Types
import Data.Dynamic
import Control.Exception
import Workflow.Util.ListUtil

data XmlException = MissingRequiredAttr String String
  deriving (Show,Typeable)

readAttr :: Element -> String -> String
readAttr element name = head $ map (\(val,_)->val) $ attributed name (keep) (CElem element)

missingAttr :: String -> String -> a
missingAttr elemName attrName = throwDyn $ MissingRequiredAttr elemName attrName

handleXml :: (XmlException -> IO a) -> IO a -> IO a
handleXml f a = catchDyn a f

readRequiredAttr :: Element -> String -> String
readRequiredAttr element name
    | isMissing = missingAttr (elementName element) name
    | otherwise = head attrList
    where
        attrList  = map (\(val,_)->val) $ attributed name (keep) (CElem element)
        attr      = (trim.head) attrList
        isMissing = null attrList || null attr

readOptionalAttr :: Element -> String -> String -> String
readOptionalAttr element name defaultValue
    | null attrList = defaultValue
    | otherwise     = head attrList
    where
        attrList = map (\(val,_)->val) $ attributed name (keep) (CElem element)

toElem :: [Content] -> [Element]
toElem []                     = []
toElem ((CElem element:rest)) = element : toElem rest
toElem (_:rest)               = toElem rest

elementName :: Element -> String
elementName (Elem name _ _) = name

getChildren :: Element -> [Element]
getChildren element = toElem $ (elm `o` children) (CElem element)

rootElement :: Document -> Element
rootElement (Document _ _ element _ ) = element

readText :: Element -> String -> String
readText element name = concatMap (stripMaybe.fst) $ filter (onlyJust) labels
    where
        onlyJust (Nothing,_)  = False
        onlyJust ((Just _),_) = True
        stripMaybe (Just x)   = x
        stripMaybe Nothing    = error "XmlUtil.stripMaybe should never be called with Nothing"
        labels                = textlabelled ( path [ children, tag name, children, txt ] ) (CElem element)
