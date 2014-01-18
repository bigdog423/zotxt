# -*- coding: utf-8 -*-
require 'minitest/autorun'
require 'httpclient'
require 'json'

class ZotxtTest < MiniTest::Unit::TestCase
  def setup
    @client = HTTPClient.new
    @base_url = "http://localhost:23119/zotxt"
    @item_url = "#{@base_url}/items"
    @complete_url = "#{@base_url}/complete"
    @bibliography_url = "#{@base_url}/bibliography"
    @search_url = "#{@base_url}/search"
  end

  def test_items_nothing
    resp = @client.get(@item_url)
    assert_equal 400, resp.status
  end

  def test_items_easykey
    resp = @client.get(@item_url, {"easykey" => "DoeBook2005"})
    assert_equal 200, resp.status
    i = JSON.parse(resp.body)
    assert_equal "book", i[0]["type"]
    assert_equal "First Book", i[0]["title"]
    assert_equal "Doe", i[0]["author"][0]["family"]
  end

  def test_items_easykey_key_format
    resp = @client.get(@item_url, {"easykey" => "DoeBook2005", "format" => "key"})
    assert_equal 200, resp.status
    i = JSON.parse(resp.body)
    assert_equal "0_ZBZQ4KMP", i[0]
  end

  def test_items_easykey_alternate_key_format
    resp = @client.get(@item_url, {"easykey" => "doe:2005book", "format" => "key"})
    assert_equal 200, resp.status
    i = JSON.parse(resp.body)
    assert_equal "0_ZBZQ4KMP", i[0]
  end

  def test_items_easykey_bibliography_format
    resp = @client.get(@item_url, {"easykey" => "DoeBook2005", "format" => "bibliography"})
    assert_equal 200, resp.status
    i = JSON.parse(resp.body)
    assert (i[0].key? 'html')
  end

  def test_items_key
    resp = @client.get(@item_url, {"key" => "0_ZBZQ4KMP", "format" => "key"})
    assert_equal 200, resp.status
    i = JSON.parse(resp.body)
    assert_equal "0_ZBZQ4KMP", i[0]
  end

  def test_items_multiple_easykeys
    resp = @client.get(@item_url, {"easykey" => "DoeBook2005,DoeArticle2006", "format" => "key"})
    assert_equal 200, resp.status
    i = JSON.parse(resp.body)
    assert_equal 2, i.length
  end

  def test_items_multiple_keys
    resp = @client.get(@item_url, {"key" => "0_ZBZQ4KMP,0_4T8MCITQ", "format" => "key"})
    assert_equal 200, resp.status
    i = JSON.parse(resp.body)
    assert_equal 2, i.length
  end

  def test_selected
    resp = @client.get(@item_url, {"selected" => "selected" })
    assert_equal 200, resp.status
    i = JSON.parse(resp.body)
  end

  def test_bibliography
    r = {
      "styleId" => "chicago-author-date",
      "citationGroups" => [
        { "citationItems" => [ { "easyKey" => "DoeBook2005" } ],
          "properties" => { "noteIndex" => 0 } }
      ]
    }
    header = { 'Content-Type' => 'application/json' }
    resp = @client.post(@bibliography_url, :header=>header, :body=>JSON.dump(r))
    assert_equal 200, resp.status
    i = JSON.parse(resp.body)
    assert_equal ["(Doe 2005)"], i["citationClusters"]
  end

  def test_bad_bibliography
    r = {
      "styleId" => "chicago-author-date",
      "citationGroups" => [
        { "citationItems" => [ { "easyKey" => "FooBar0000" } ],
          "properties" => { "noteIndex" => 0 } }
      ]
    }
    header = { 'Content-Type' => 'application/json' }
    resp = @client.post(@bibliography_url, :header=>header, :body=>JSON.dump(r))
    assert_equal 400, resp.status
  end

  def test_no_param
    resp = @client.get(@item_url)
    assert_equal 400, resp.status
  end

  def test_all
    resp = @client.get(@item_url, {"all" => "all", "format" => "key"})
    assert_equal 200, resp.status
  end

  def test_bad_easykey
    resp = @client.get(@item_url, {"easykey" => "XXX"})
    assert_equal 400, resp.status
  end

  def test_unicode_easykey
    resp = @client.get(@item_url, {"easykey" => "HüningRelatie2012"})
    assert_equal 200, resp.status
  end

  def test_bad_easykey
    resp = @client.get(@item_url, {"easykey" => "XXX"})
    assert_equal 400, resp.status
  end

  def test_custom_key
    resp = @client.get(@item_url, {"easykey" => "hüning:2012foo"})
    assert_equal 200, resp.status
  end

  def test_collection_search
    resp = @client.get(@item_url, {"collection" => "My%20citations"})
    assert_equal 200, resp.status
  end

  def test_format_bibtex
    resp = @client.get(@item_url, {"key" => "0_4T8MCITQ", "format" => "bibtex"})
    assert_equal 200, resp.status
    assert_equal("""
@article{doe_article_2006,
	title = {Article},
	volume = {6},
	journal = {Journal of Generic Studies},
	author = {Doe, John},
	year = {2006},
	pages = {33--34}
}""", resp.body)
  end

  def test_format_bibliography
    resp = @client.get(@item_url, {"key" => "0_4T8MCITQ", "format" => "bibliography"})
    assert_equal 200, resp.status
    results = JSON.parse(resp.body)
    assert_equal({"text"=>"Doe, John. “Article.” Journal of Generic Studies 6 (2006): 33–34.", 
                   "html"=>"""<div style=\"line-height: 1.35; padding-left: 2em; text-indent:-2em;\" class=\"csl-bib-body\">
  <div class=\"csl-entry\">Doe, John. “Article.” <i>Journal of Generic Studies</i> 6 (2006): 33–34.</div>
  <span class=\"Z3988\" title=\"url_ver=Z39.88-2004&amp;ctx_ver=Z39.88-2004&amp;rfr_id=info%3Asid%2Fzotero.org%3A2&amp;rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal&amp;rft.genre=article&amp;rft.atitle=Article&amp;rft.jtitle=Journal%20of%20Generic%20Studies&amp;rft.volume=6&amp;rft.aufirst=John&amp;rft.aulast=Doe&amp;rft.au=John%20Doe&amp;rft.date=2006&amp;rft.pages=33-34&amp;rft.spage=33&amp;rft.epage=34\"></span>
</div>""", 
                   "key"=>"0_4T8MCITQ"}, results[0])
  end

  def test_format_easykey
    resp = @client.get(@item_url, {"key" => "0_4T8MCITQ", "format" => "easykey"})
    assert_equal 200, resp.status
    results = JSON.parse(resp.body)
    assert_equal "doe:2006article", results[0]
  end

  def test_format_key
    resp = @client.get(@item_url, {"key" => "0_4T8MCITQ", "format" => "key"})
    assert_equal 200, resp.status
    results = JSON.parse(resp.body)
    assert_equal "0_4T8MCITQ", results[0]
  end

  def test_format_json
    resp = @client.get(@item_url, {"key" => "0_4T8MCITQ", "format" => "json"})
    assert_equal 200, resp.status
    results = JSON.parse(resp.body)
    assert_equal({"id"=>2858,
      "type"=>"article-journal",
      "title"=>"Article", 
      "container-title"=>"Journal of Generic Studies", 
      "page"=>"33-34", 
      "volume"=>"6",
      "author"=>[{"family"=>"Doe", "given"=>"John"}], 
      "issued"=>{"date-parts"=>[["2006"]]}
                   }, results[0])
  end

  def test_completion
    resp = @client.get(@complete_url, {"easykey" => "Doe"})
    results = JSON.parse(resp.body)
    assert (results.size > 1)
    
    resp = @client.get(@complete_url, {"easykey" => "DoeArticle2006"})
    results = JSON.parse(resp.body)
    assert_equal 1, results.size
  end
  
  def test_search
    resp = @client.get(@search_url, {"q" => "doe article", "format" => "key"})
    assert_equal 200, resp.status
    results = JSON.parse(resp.body)
    assert_equal "0_4T8MCITQ", results[0]
  end    
end
