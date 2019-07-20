module Main where

import Data.Version hiding (Version (..))
import Paths_idiomaticca
import Options.Applicative
import Debug.Trace
import qualified Language.C as C
import qualified Language.ATS as A
import Language.Idiomaticca

wrapper :: ParserInfo Command
wrapper = info (helper <*> versionInfo <*> command')
  (fullDesc
   <> progDesc "The idiomaticca translates IDIOMATIC C into readable ATS."
   <> header "idiomaticca - a tool to translate IDIOMATIC C into readable ATS")

versionInfo :: Parser (a -> a)
versionInfo = infoOption
  ("idiomaticca version: " ++ showVersion version)
  (short 'V' <> long "version" <> help "Show version")

data Command = Trans { _file :: String }
             | DumpAts { _file :: String }
             | DumpC { _file :: String }

command' :: Parser Command
command' = hsubparser
  (command "trans" (info trans (progDesc "Translate C into ATS"))
  <> command "dumpats" (info dumpats (progDesc "Dump AST of ATS code"))
  <> command "dumpc" (info dumpc (progDesc "Dump AST of C code"))
  )

trans :: Parser Command
trans = Trans <$> targetP mempty id "C filename"

dumpats :: Parser Command
dumpats = DumpAts <$> targetP mempty id "ATS filename"

dumpc :: Parser Command
dumpc = DumpC <$> targetP mempty id "C filename"

targetP :: Mod ArgumentFields String -> (Parser String -> a) -> String -> a
targetP completions' f s = f
  (argument str
   (metavar "TARGET"
    <> help ("Targets to " <> s)
    <> completions'))

main :: IO ()
main = execParser wrapper >>= run

run :: Command -> IO ()
run (Trans file) = C.parseCFilePre file >>= printAtsCode
run (DumpC file) = C.parseCFilePre file >>= printCAst
run (DumpAts file) = do
  atsSrc <- readFile file
  let atsAstE = A.parse atsSrc
  printAtsAst atsAstE

printAtsCode :: Either C.ParseError C.CTranslUnit -> IO ()
printAtsCode (Left err) = traceShow err undefined
printAtsCode (Right cAst) = do
  let atsAst = interpretTranslationUnit cAst
  putStrLn $ A.printATS atsAst

printCAst :: Either C.ParseError C.CTranslUnit -> IO ()
printCAst (Left err) = traceShow err undefined
printCAst (Right cAst) = print cAst

printAtsAst :: Either A.ATSError (A.ATS A.AlexPosn) -> IO ()
printAtsAst (Left err) = traceShow err undefined
printAtsAst (Right atsAst) = print atsAst
