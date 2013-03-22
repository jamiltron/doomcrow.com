--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Control.Applicative ((<$>))
import           Data.Monoid         (mappend, mconcat)
import           Hakyll


--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do

    match "games/*" $ do
        route   idRoute
        compile copyFileCompiler

    match ("images/*" .||. "robots.txt" .||. "favicon.ico" ) $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match (fromList ["about.rst", "contact.markdown", "games.markdown", "homunculus.markdown"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
	    >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    create ["rss.xml"] $ do
        route idRoute
        compile $ do
           posts <- recentFirst <$> loadAllSnapshots "posts/*" "content"
	   renderRss myFeedConfiguration feedCtx posts

    create ["atom.xml"] $ do
        route idRoute
	compile $ do
	   posts <- recentFirst <$> loadAllSnapshots "posts/*" "content"
	   renderAtom myFeedConfiguration feedCtx posts
	  

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            let archiveCtx =
                    field "posts" (\_ -> postList recentFirst) `mappend`
                    constField "title" "Archives"              `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls

    match "index.html" $ do
        route idRoute
        compile $ do
            let indexCtx = field "posts" $ \_ -> postList (take 5 . recentFirst)

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" postCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateCompiler


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

--------------------------------------------------------------------------------
postList :: ([Item String] -> [Item String]) -> Compiler String
postList sortFilter = do
    posts   <- sortFilter <$> loadAll "posts/*"
    itemTpl <- loadBody "templates/post-item.html"
    list    <- applyTemplateList itemTpl postCtx posts
    return list

-------------------------------------------------------------------------------
myFeedConfiguration :: FeedConfiguration
myFeedConfiguration   = FeedConfiguration
    { feedTitle       = "Doom Crow"
    , feedDescription = "Game development by a one-man studio"
    , feedAuthorName  = "Justin Hamilton"
    , feedAuthorEmail = "justin@doomcrow.com"
    , feedRoot        = "http://www.doomcrow.com"
    }

feedCtx :: Context String
feedCtx =
    bodyField "description" `mappend`
    postCtx