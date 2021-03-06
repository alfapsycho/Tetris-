-- | Types and functions for shapes. The list of all tetris pieces.
module Shapes where
import Data.List(transpose)
import Data.Maybe(isNothing, isJust)
import Test.QuickCheck

-- * Shapes

type Square = Maybe Colour

data Colour = Black | Red | Green | Yellow | Blue | Purple | Cyan | Grey
              deriving (Eq,Bounded,Enum,Show)

-- | A geometric shape is represented as a list of lists of squares. Each square
-- can be empty or filled with a block of a specific colour.

-- S constructor - []
data Shape = S [Row] deriving (Eq)
type Row = [Square]

rows :: Shape -> [Row]
rows (S rs) = rs

-- * Showing shapes

showShape :: Shape -> String
showShape s = unlines [showRow r | r <- rows s]
  where
    showRow :: Row -> String
    showRow r = [showSquare s | s <- r]

    showSquare Nothing = '.'
    showSquare (Just Black) = '#' -- can change to '█' on linux/mac
    showSquare (Just Grey)  = 'g' -- can change to '▓'
    showSquare (Just c)     = head (show c)

instance Show Shape where
  show = showShape
  showList ss r = unlines (map show ss)++r


-- * The shapes used in the Tetris game

-- | All 7 tetrominoes (all combinations of connected 4 blocks),
-- see <https://en.wikipedia.org/wiki/Tetromino>
allShapes :: [Shape]
allShapes = [S (makeSquares s) | s <- shapes]
   where
      makeSquares = map (map colour)
      colour c    = lookup c [('I',Red),('J',Grey),('T',Blue),('O',Yellow),
                              ('Z',Cyan),('L',Green),('S',Purple)]
      shapes =
              [["I",
               "I",
               "I",
               "I"],
              [" J",
               " J",
               "JJ"],
              [" T",
               "TT",
               " T"],
              ["OO",
               "OO"],
              [" Z",
               "ZZ",
               "Z "],
              ["LL",
               " L",
               " L"],
              ["S ",
               "SS",
               " S"]]

-- * Some simple functions
testShape = allShapes !! 1
testShape2 = allShapes !! 2
testShape3 = allShapes !! 0
testRows = rows testShape
testRows2 = rows testShape2
testRows3 = rows testShape3
testRow = head testRows
testRow2 = head testRows2
errorShape = (S [[Nothing,Nothing,Nothing,Nothing,Nothing],[Nothing,Nothing,Nothing]])


-- ** A01
emptyShape :: (Int,Int) -> Shape
emptyShape(c, r) = S(replicate r c1)
  where
    c1 = emptyShape' c

--Helper funktion for getting the first row.
emptyShape' n = replicate n Nothing

-- ** A02
-- | The size (width and height) of a shape
shapeSize :: Shape -> (Int,Int)
shapeSize (S rs) = (length(head(rs)), length(rs))

-- ** A03
-- | Count how many non-empty squares a shape contains
-- Kan användas isNothing, Filter
blockCount :: Shape -> Int
blockCount shape = length([c | c <- list, isJust c])
  where
     list = concat(rows shape)

-- * The Shape invariant
-- ** A04
propShape  :: Shape -> Bool
propShape (S rs) = colAndRow && isRec
  where
    (col, row) = shapeSize(S rs) -- Gathers the size of the shape
    colAndRow = and([col > 0]++[row > 0]) -- Checks that the row and col must be of length >0, otherwise there can't be a shape, as the smallest shape is 1x1
    intList = map length rs               -- Maps the length to each element of the rows to get an int list of the length of the rows.
    isRec = minimum(intList) == maximum(intList) -- Checks that the length of the rows are the same

-- * Test data generators

-- ** A05
-- | A random generator for colours
color_list = enumFrom Black     -- Creates a list of all the Colours

rColour :: Gen Colour
rColour =  elements color_list

instance Arbitrary Colour where
  arbitrary = rColour

-- ** A06
-- | A random generator for shapes
rShape :: Gen Shape
rShape = elements allShapes

instance Arbitrary Shape where
  arbitrary = rShape

-- * Transforming shapes

-- ** A07
-- | Rotate a shape 90 degrees
rotateShape :: Shape -> Shape
rotateShape shape = new_shape
  where
    rows' = rows shape
    transposed = transpose(reverse(rows'))  --
    new_shape = (S transposed)   --


-- ** A08
-- | shiftShape adds empty squares above and to the left of the shape
shiftShape :: (Int,Int) -> Shape -> Shape
shiftShape (col, row) shape = finalShape
  where
    (tPaddedShape, _) = hPadding(col, row) shape      -- Padds Top, and return the new Shape
    (finalShape, _) = vPadding(col, row) tPaddedShape -- Padds the leftSide of the new Shape and returns a final Shape.


hPadding :: (Int, Int) -> Shape -> (Shape, Shape)
hPadding (col, row) shape = finalShapes
  where
    (currCol, currRow) = shapeSize(shape)        -- Gather the sizes that we can use for the Padding
    emptyRowToAppend = emptyShape(currCol, row)  -- Creates the padding we're gonna append.
    topPad = rows emptyRowToAppend ++ rows shape -- Appending the empty rows to the top of the Shape
    botPad = rows shape ++ rows emptyRowToAppend -- Appending the empty rows to the bottom of the Shape
    finalShapes = ((S topPad),(S botPad))        -- Returns the both padded shapes as a pair for pattern matching


vPadding :: (Int,Int) -> Shape -> (Shape, Shape)
vPadding (col, _) shape = finalShape
  where
    (_, curRow) = shapeSize(shape)                            -- Gather the sizes from Original Shape
    emptyRowToAppend = emptyShape(curRow, col)                -- Creates the padding we're gonna append.
    firstTransposedShape = transpose (rows shape)             -- Transposing the row so we can append a row onTop of it
    paddLeft = rows emptyRowToAppend ++ firstTransposedShape  -- Appending the rows on top of it
    paddRight = firstTransposedShape ++ rows emptyRowToAppend -- Appending the rows at the bottom of it
    transposeBackL = transpose paddLeft                       -- Transposing the shape back to it's previous form but Left Padded
    transposeBackR = transpose paddRight                      -- Transposing the shape back to it's previous form but Right Padded
    finalShape = ((S transposeBackL),(S transposeBackR))      -- Creates the final shape to return


-- ** A09
-- | padShape adds empty sqaure below and to the right of the shape
padShape :: (Int,Int) -> Shape -> Shape
padShape (col, row) shape = finalShape
  where
    (_, bPaddedShape) = hPadding(col, row) shape      -- Padds bottom, and return the new Shape
    (_, finalShape) = vPadding(col, row) bPaddedShape -- Padds the Right of the new Shape and returns a final Shape.


-- ** A10
-- | pad a shape to a given size
padShapeTo :: (Int,Int) -> Shape -> Shape
padShapeTo (col, row) shape = padding
  where
    (curCol, curRow) = shapeSize shape                    -- Gets the current Size of the Shape
    padding = padShape ((col-curCol),(row-curRow)) shape  -- Pads to the given sizen, by adding the difference

-- * Comparing and combining shapes
-- B01
overlaps :: Shape -> Shape -> Bool
overlaps (S rs1) (S rs2) = or $ zipWith rowsOverlap rs1 rs2 -- Vi vill att Raderna ska få funktionen rowsOverlap callad på sig, där varje rad iterativ gås igenom för de båda [rowsen]

rowsOverlap :: Row -> Row -> Bool
rowsOverlap row1 row2 = or $ zipWith squareOverlapping row1 row2  -- Vi vill att varje element(Square) i raden ska få en funktion callad på sig, slutligen vill vi utvärdera detta med or
  where squareOverlapping sq1 sq2 = isJust sq1 && isJust sq2 -- funktionen tar in 2 argument och Om båda elementen är isJust så True, annars false. vi får en lista [False, True etc]

--B02
zipShapeWith ::(Square -> Square -> Square) -> Shape -> Shape -> Shape
zipShapeWith function (S rs1) (S rs2) = S $ zipWith (zipWith function) rs1 rs2

clash :: Square -> Square -> Square
clash Nothing s       =  s
clash s       Nothing =  s
clash _             _ = Just Black


combine :: Shape -> Shape -> Shape
combine s1 s2 = zipShapeWith clash p1 p2
  where
    ((c1, r1):(c2, r2):_) = map shapeSize [s1, s2] -- Gets the col and rows
    (mC:mR:_) = zipWith max [c1, r1] [c2,r2]      -- gets the max val for col and rows
    (p1:p2:_) = map (padShapeTo (mC,mR)) [s1,s2]  -- maps the padding to both shapes, then extract
