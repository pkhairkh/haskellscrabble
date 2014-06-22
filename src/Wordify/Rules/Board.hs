module Wordify.Rules.Board(Board, allSquares, emptyBoard, placeTile, occupiedSquareAt,
 lettersAbove, lettersBelow, lettersLeft, lettersRight, unoccupiedSquareAt) where

  import Wordify.Rules.Square
  import Wordify.Rules.Pos
  import Data.Maybe
  import Wordify.Rules.Tile
  import qualified Data.Map as Map
  import Control.Monad
  import Data.Sequence as Seq
  import Wordify.Rules.Board.Internal
  import Control.Applicative

  {- |
    Returns all the squares on the board, ordered by column then row.
  -}
  allSquares :: Board -> [(Pos, Square)]
  allSquares (Board squares) = Map.toList squares

  {- |
    Places a tile on a square and yields the new board, if the 
    target square is empty. Otherwise yields 'Nothing'.
  -}
  placeTile :: Board -> Tile -> Pos -> Maybe Board
  placeTile board tile pos = 
    (\sq -> insertSquare board pos (putTileOn sq tile)) <$> unoccupiedSquareAt board pos

  insertSquare :: Board -> Pos -> Square -> Board
  insertSquare (Board squares) pos square = Board $ Map.insert pos square squares

  squareAt :: Board -> Pos -> Maybe Square
  squareAt (Board squares)  = flip Map.lookup squares

  {- | Returns the square at a given position if it is not occupied by a tile. Otherwise returns Nothing.-}
  unoccupiedSquareAt :: Board -> Pos -> Maybe Square
  unoccupiedSquareAt board pos = 
    squareAt board pos >>= (\sq -> if isOccupied sq then Nothing else Just sq)

  {- | Returns the square at a given position if it is occupied by a tile. Otherwise returns Nothing.-}
  occupiedSquareAt :: Board -> Pos -> Maybe Square
  occupiedSquareAt board pos = squareAt board pos >>= squareIfOccupied
 
  {- | All letters immediately above a given square until a non-occupied square -}
  lettersAbove :: Board -> Pos -> Seq (Pos,Square)
  lettersAbove board pos = walkFrom board pos above

  {- | All letters immediately below a given square until a non-occupied square -}
  lettersBelow :: Board -> Pos -> Seq (Pos,Square)
  lettersBelow board pos = Seq.reverse $ walkFrom board pos below

  {- | All letters immediately left of a given square until a non-occupied square -}
  lettersLeft :: Board -> Pos -> Seq (Pos,Square)
  lettersLeft board pos = Seq.reverse $ walkFrom board pos left

  {- | All letters immediately right of a given square until a non-occupied square -}
  lettersRight :: Board -> Pos -> Seq (Pos,Square)
  lettersRight board pos = walkFrom board pos right

  {-
    Walks the tiles from a given position in a given direction
    until an empty square is found or the boundary of the board
    is reached.
  -}
  walkFrom :: Board -> Pos -> (Pos -> Maybe Pos) -> Seq (Pos,Square)
  walkFrom board pos direction = maybe mzero (\(next,sq) ->
   (next, sq) <| walkFrom board next direction) neighbourPos
    where
      neighbourPos = direction pos >>= \nextPos -> occupiedSquareAt board nextPos >>=
        \sq -> return (nextPos, sq)

  {- |
    Creates an empty board. 
  -}
  emptyBoard :: Board
  emptyBoard = Board (Map.fromList posSquares)
    where
      layout = 
        [["TW","N","N","DL","N","N","N","TW","N","N","N","DL","N","N","TW"]
       ,["N","DW","N","N","N","TL","N","N","N","TL","N","N","N","DW","N"]
       ,["N","N","DW","N","N","N","DL","N","DL","N","N","N","DW","N","N"]
       ,["DL","N","N","DW","N","N","N","DL","N","N","N","DW","N","N","DL"]
       ,["N","N","N","N","DW","N","N","N","N","N","DW","N","N","N","N"]
       ,["N","TL","N","N","N","TL","N","N","N","TL","N","N","N","TL","N"]
       ,["N","N","DL","N","N","N","DL","N","DL","N","N","N","DL","N","N"]
       ,["TW","N","N","DL","N","N","N","DW","N","N","N","DL","N","N","TW"]
       ,["N","N","DL","N","N","N","DL","N","DL","N","N","N","DL","N","N"]
       ,["N","TL","N","N","N","TL","N","N","N","TL","N","N","N","TL","N"]
       ,["N","N","N","N","DW","N","N","N","N","N","DW","N","N","N","N"]
       ,["DL","N","N","DW","N","N","N","DL","N","N","N","DW","N","N","DL"]
       ,["N","N","DW","N","N","N","DL","N","DL","N","N","N","DW","N","N"]
       ,["N","DW","N","N","N","TL","N","N","N","TL","N","N","N","DW","N"]
       ,["TW","N","N","DL","N","N","N","TW","N","N","N","DL","N","N","TW"]]

      squares = (map . map) toSquare layout
      columns = Prelude.zip [1..15] squares
      labeledSquares= concatMap (uncurry columnToMapping) columns
      columnToMapping columnNo columnSquares = Prelude.zipWith (\sq y -> ((columnNo,y),sq)) columnSquares [1..15]
      posSquares = mapMaybe (\((x,y), sq) -> fmap (\pos -> (pos, sq)) (posAt (x,y))) labeledSquares

      toSquare :: String -> Square
      toSquare "DL" = DoubleLetter Nothing
      toSquare "TL" = TripleLetter Nothing
      toSquare "DW" = DoubleWord Nothing
      toSquare "TW" = TripleWord Nothing
      toSquare _ = Normal Nothing


