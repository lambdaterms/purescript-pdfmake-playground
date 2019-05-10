module Test.Dsl2 where

import Prelude

import Data.Foldable (fold)
import Data.Nullable (null)
import Data.Tuple.Nested ((/\))
import Data.Typelevel.Num (D1, D2, D3, D8, d1, d2, d3, d5)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Foreign.Object (fromFoldable)
import PdfMake.Dsl2 (Cell(..), PrimCell(..), Table(..), TableH(..), addCols, addRows, addTables, fromCell, mkCell, mkEmpty, toTable, (++), (|||))
import PdfMake.Unsafe (Content, DocDefinition, createPdf)
import Test.Utils (defaultContent, defaultStyle, nn, setStyle, table, text)

toContent ∷ PrimCell String → Content
toContent = case _ of
  Empty → defaultContent
  PrimCell { value, rowSpan, colSpan } → 
    let rs = if rowSpan == 1 then null else nn rowSpan in
    let cs = if colSpan == 1 then null else nn colSpan in
    defaultContent
      { text = nn value, rowSpan = rs, colSpan = cs }

mkCell' ∷ ∀ a. a → Cell a D1 D1
mkCell' = mkCell d1 d1

mk ∷ ∀ a. a → TableH a D1 D1
mk = fromCell <<< mkCell'

logoPart ∷ TableH String D3 D3
logoPart = logoElem ++ rightHeader
  where
    logoElem ∷ TableH String D1 D3
    logoElem = fromCell $ mkCell d1 d3 "logo"

    rightHeader ∷ TableH String D2 D3
    rightHeader = 
      mk "prof" ++ mk "emp" |||
      mk "issueDate" ++ mk "dueDate" |||
      mk "issueDate_" ++ mk "dueDate_"

listPart ∷ Table String D8
listPart = header `addTables` list `addTables` footer
  where
    elem (no /\ name /\ unit /\ qty /\ price /\ ammount /\ vat /\ gross) = toTable $
      mk no ++ mk name ++ mk unit ++ mk qty ++ mk price ++ mk ammount ++ mk vat ++ mk gross
    list = fold $ map elem
      [ "1" /\ "VIDEO STREAMS [montly subscription]\nstart:2019-03-15; host:stream4.nadaje.com:8580; max recipients:50" 
        /\ "service" /\ "1" /\ "zl123.32" /\ "zl123.32" /\ "23%" /\ "zl123.42"
      , "2" /\ "VIDEO STREAMS [montly subscription]\nstart:2019-06-15; host:stream4.nadaje.com:8580; max recipients:70" 
        /\ "service" /\ "3" /\ "zl155.32" /\ "zl123.32" /\ "23%" /\ "zl123.42"
      ]
    footer = toTable $ mkEmpty d5 d2 ++ 
      ( mk "Net Amount" ++ mk "VAT" ++ mk "Gross"
      ||| mk "zl1323.32" ++ mk "23%" ++ mk "zl4421.42"
      )
    header = toTable $ mk "No." ++ mk "Name" ++ mk "Unit" ++ mk "Qty"
      ++ mk "Net price" ++ mk "Net Amount" ++ mk "VAT rate" ++ mk "Gross"

tableToContent ∷ ∀ w. Table String w → Content
tableToContent (Table t) = table $ map (map toContent) t

dd ∷ DocDefinition
dd = 
  let dc = defaultContent in
  { content: 
      [ text "dd dsl"
      , setStyle "tableStyle" $ tableToContent $ toTable logoPart
      , setStyle "tableStyle" $ tableToContent listPart
      ]
  , defaultStyle: nn $ defaultStyle { font = nn "Helvetica" }
  , styles: fromFoldable
      [ "tableStyle" /\ defaultStyle { margin = nn [0, 5, 0, 15] }

      ]
  }

main ∷ Effect Unit
main = launchAff_ do
  createPdf dd "etc/dsl-dd.pdf"
