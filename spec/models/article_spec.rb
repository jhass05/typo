require File.dirname(__FILE__) + '/../spec_helper'

describe Article do

  before do
    @articles = []
  end

  describe 'Factory Girl' do
    it 'should article factory valid' do
      Factory(:article).should be_valid
      Factory.build(:article).should be_valid
    end
    it 'should second_article factory valid' do
      Factory(:second_article).should be_valid
      Factory.build(:second_article).should be_valid
    end
    it 'should article_with_accent_in_html' do
      Factory(:article_with_accent_in_html).should be_valid
      Factory.build(:article_with_accent_in_html).should be_valid
    end
    it 'should store user too' do
      a = Factory(:article)
      a.user.should be_valid
      Article.find(a.id).user.should_not be_nil
    end
    it 'should create multiple valid articles' do
      Factory(:article).should be_valid
      Factory(:article).should be_valid
    end
  end

  def assert_results_are(*expected)
    assert_equal expected.size, @articles.size
    expected.each do |i|
      assert @articles.include?(i.is_a?(Symbol) ? contents(i) : i)
    end
  end

  it "test_content_fields" do
    a = Article.new
    assert_equal [:body, :extended], a.content_fields
  end

  it "test_permalink_url with hostname" do
    assert_equal 'http://myblog.net/2004/06/01/article-3', contents(:article3).permalink_url(anchor=nil, only_path=false)
  end

  it "test_permalink_url only path" do
    assert_equal '/2004/06/01/article-3', contents(:article3).permalink_url(anchor=nil, only_path=true)
  end

  it "test_edit_url" do
    a = contents(:article3)
    assert_equal "http://myblog.net/admin/content/edit/#{a.id}", a.edit_url
  end

  it "test_delete_url" do
    a = contents(:article3)
    assert_equal "http://myblog.net/admin/content/destroy/#{a.id}", a.delete_url
  end

  it "test_feed_url" do
    a = contents(:article3)
    assert_equal "http://myblog.net/2004/06/01/article-3.atom", a.feed_url(:atom10)
    assert_equal "http://myblog.net/2004/06/01/article-3.rss", a.feed_url(:rss20)
  end

  it "test_create" do
    a = Article.new
    a.user_id = 1
    a.body = "Foo"
    a.title = "Zzz"
    assert a.save

    a.categories << Category.find(categories(:software).id)
    assert_equal 1, a.categories.size

    b = Article.find(a.id)
    assert_equal 1, b.categories.size
  end

  it "test_permalink_with_title" do
    assert_equal( contents(:article3),
                  Article.find_by_permalink({:year => 2004, :month => 06, :day => 01, :title => "article-3"}) )
    assert_raises(ActiveRecord::RecordNotFound) do
      Article.find_by_permalink :year => 2005, :month => "06", :day => "01", :title => "article-5"
    end
  end

  it "test_strip_title" do
    assert_equal "article-3", "Article-3".to_url
    assert_equal "article-3", "Article 3!?#".to_url
    assert_equal "there-is-sex-in-my-violence", "There is Sex in my Violence!".to_url
    assert_equal "article", "-article-".to_url
    assert_equal "lorem-ipsum-dolor-sit-amet-consectetaur-adipisicing-elit", "Lorem ipsum dolor sit amet, consectetaur adipisicing elit".to_url
    assert_equal "my-cats-best-friend", "My Cat's Best Friend".to_url
  end

  it "test_perma_title" do
    assert_equal "article-1", contents(:article1).stripped_title
    assert_equal "article-2", contents(:article2).stripped_title
    assert_equal "article-3", contents(:article3).stripped_title
  end

  it "test_html_title" do
    a = Article.new
    a.title = "This <i>is</i> a <b>test</b>"
    assert a.save

    assert_equal 'this-is-a-test', a.permalink
  end

  it "test_multibyte_title" do
    a = Article.new
    a.title = "ルビー"
    assert a.save

    assert_equal '%E3%83%AB%E3%83%93%E3%83%BC', a.permalink
  end

  describe "the html_urls method" do
    it "test_urls" do
      urls = contents(:article4).html_urls
      assert_equal ["http://www.example.com/public"], urls
    end

    it "should only match the href attribute" do
      a = Factory.create :article
      a.body = '<a href="http://a/b">a</a> <a fhref="wrong">wrong</a>'
      urls = a.html_urls
      assert_equal ["http://a/b"], urls
    end

    it "should match across newlines" do
      a = Factory.create :article
      a.body = "<a\nhref=\"http://foo/bar\">foo</a>"
      urls = a.html_urls
      assert_equal ["http://foo/bar"], urls
    end

    it "should match with single quotes" do
      a = Factory.create :article
      a.body = "<a href='http://foo/bar'>foo</a>"
      urls = a.html_urls
      assert_equal ["http://foo/bar"], urls
    end

    it "should match with no quotes" do
      a = Factory.create :article
      a.body = "<a href=http://foo/bar>foo</a>"
      urls = a.html_urls
      assert_equal ["http://foo/bar"], urls
    end
  end

  ### XXX: Should we have a test here?
  it "test_send_pings" do
  end

  ### XXX: Should we have a test here?
  it "test_send_multiple_pings" do
  end

  it "test_tags" do
    a = Article.new(:title => 'Test tag article',
                    :keywords => 'test tag tag stuff');

    assert_kind_of Article, a
    assert_equal 0, a.tags.size

    a.keywords_to_tags

    assert_equal 3, a.tags.size
    assert_equal ["test", "tag", "stuff"].sort , a.tags.collect {|t| t.name}.sort
    assert a.save

    a.keywords = 'tag bar stuff foo'
    a.keywords_to_tags

    assert_equal 4, a.tags.size
    assert_equal ["foo", "bar", "tag", "stuff"].sort , a.tags.collect {|t| t.name}.sort

    a.keywords='tag bar'
    a.keywords_to_tags

    assert_equal 2, a.tags.size

    a.keywords=''
    a.keywords_to_tags

    assert_equal 0, a.tags.size

    b = Article.new(:title => 'Tag Test 2',
                    :keywords => 'tag test article one two three')

    assert_kind_of Article,b
    assert_equal 0, b.tags.size

    c = Article.new(:title => 'Foo', :keywords => 'test "tag test" web2.0')
    c.keywords_to_tags

    assert_equal 3, c.tags.size
    assert_equal ['test', 'tagtest', 'web2-0'].sort, c.tags.collect(&:name).sort
  end

  it "test_find_published_by_tag_name" do
    @articles = Tag.find_by_name(tags(:foo).name).published_articles

    assert_results_are(:article1, :article2, :publisher_article)
  end


  it "test_find_published" do
    @articles = Article.find_published
    assert_results_are(:search_target, :article1, :article2,
                       :article3, :inactive_article,:xmltest,
                       :spammed_article, :publisher_article, :markdown_article, :utf8_article)

    @articles = Article.find_published(:all,
                                                  :conditions => "title = 'Article 1!'")
    assert_results_are :article1
  end

  it "test_just_published_flag" do
    art = Article.new(:title => 'title',
                                   :body => 'body',
                                   :published => true)
    assert art.just_changed_published_status?
    assert art.save

    art = Article.find(art.id)
    assert !art.just_changed_published_status?

    art = Article.create!(:title => 'title2',
                          :body => 'body',
                          :published => false)

    assert ! art.just_changed_published_status?
  end

  it "test_future_publishing" do
    assert_sets_trigger(Article.create!(:title => 'title', :body => 'body',
                                        :published => true,
                                        :published_at => Time.now + 4.seconds))
  end

  it "test_future_publishing_without_published_flag" do
    assert_sets_trigger Article.create!(:title => 'title', :body => 'body',
                                        :published_at => Time.now + 4.seconds)
  end

  it "test_triggers_are_dependent" do
    art = Article.create!(:title => 'title', :body => 'body',
                          :published_at => Time.now + 1.hour)
    assert_equal 1, Trigger.count
    art.destroy
    assert_equal 0, Trigger.count
  end

  def assert_sets_trigger(art)
    assert_equal 1, Trigger.count
    assert Trigger.find(:first, :conditions => ['pending_item_id = ?', art.id])
    assert !art.published
    t = Time.now
    # We stub the Time.now answer to emulate a sleep of 4. Avoid the sleep. So
    # speed up in test
    Time.stub!(:now).and_return(t + 5.seconds)
    Trigger.fire
    art.reload
    assert art.published
  end

  it "test_find_published_by_category" do
    Article.create!(:title      => "News from the future!",
                    :body       => "The future is cool!",
                    :keywords   => "future",
                    :published_at => Time.now + 12.minutes)

    @articles = Category.find_by_permalink('personal').published_articles
    assert_results_are :article1, :article2, :article3

    @articles = Category.find_by_permalink('software').published_articles
    assert_results_are :article1
  end

  it "test_find_published_by_nonexistent_category_raises_exception" do
    assert_raises ActiveRecord::RecordNotFound do
      Category.find_by_permalink('does-not-exist').published_articles
    end
  end

  it "test_destroy_file_upload_associations" do
    a = contents(:article1)
    assert_equal 2, a.resources.size
    a.resources << resources(:resource3)
    assert_equal 3, a.resources.size
    a.destroy
    assert_equal 0, Resource.find(:all, :conditions => "article_id = #{a.id}").size
  end

  it 'should notify' do
    [:randomuser, :bob].each do |tag|
      u = users(tag); u.notify_on_new_articles = true; u.save!
    end
    a = Article.new(:title => 'New Article', :body => 'Foo', :author => 'Tobi', :user => users(:tobi))
    assert a.save

    assert_equal 2, a.notify_users.size
    assert_equal ['bob', 'randomuser'], a.notify_users.collect {|u| u.login }.sort
  end

  it "test_tags_on_update" do
    contents(:article3).update_attribute :keywords, "my new tags"
    assert_equal 3, contents(:article3).reload.tags.size
    assert contents(:article3).tags.include?(Tag.find_by_name("new"))
  end

  it "test_withdrawal" do
    art = Article.find(contents(:article1).id)
    assert   art.published?
    assert ! art.withdrawn?
    art.withdraw!
    assert ! art.published?
    assert   art.withdrawn?
    art.reload
    assert ! art.published?
    assert   art.withdrawn?
  end

  it "test_default_filter" do
    a = Article.find(contents(:article1).id)
    assert_equal 'textile', a.default_text_filter.name
  end

  it 'should get only ham not spam comment' do
    contents(:article2).comments.ham.should == [feedback(:spam_comment)]
    contents(:article2).comments.count.should == 2
  end

  describe '#access_by?' do

    it 'admin should be access to an article write by another' do
      contents(:article2).should be_access_by(users(:tobi))
    end

    it 'admin should be access to an article write by himself' do
      contents(:article1).should be_access_by(users(:tobi))
    end

  end

  describe 'body_and_extended' do
    before :each do
      @article = contents(:article1)
    end

    it 'should combine body and extended content' do
      @article.body_and_extended.should ==
        "#{@article.body}\n<!--more-->\n#{@article.extended}"
    end

    it 'should not insert <!--more--> tags if extended is empty' do
      @article.extended = ''
      @article.body_and_extended.should == @article.body
    end
  end

  describe '#search' do

    describe 'is an array', :shared => true do
      it 'should get an array' do
        @articles.should be_a(Array)
      end
    end

    describe 'with several words and no result' do

      before :each do
        @articles = Article.search('hello world')
      end

      it_should_behave_like 'is an array'

      it 'should be empty' do
        @articles.should be_empty
      end
    end

    describe 'with one word and result' do

      before :each do
        @articles = Article.search('extended')
      end

      it_should_behave_like 'is an array'

      it 'should have one item' do
        assert_equal 9, @articles.size
      end
    end
  end

  describe 'body_and_extended=' do
    before :each do
      @article = contents(:article1)
    end

    it 'should split apart values at <!--more-->' do
      @article.body_and_extended = 'foo<!--more-->bar'
      @article.body.should == 'foo'
      @article.extended.should == 'bar'
    end

    it 'should remove newlines around <!--more-->' do
      @article.body_and_extended = "foo\n<!--more-->\nbar"
      @article.body.should == 'foo'
      @article.extended.should == 'bar'
    end

    it 'should make extended empty if no <!--more--> tag' do
      @article.body_and_extended = "foo"
      @article.body.should == 'foo'
      @article.extended.should be_empty
    end

    it 'should preserve extra <!--more--> tags' do
      @article.body_and_extended = "foo<!--more-->bar<!--more-->baz"
      @article.body.should == 'foo'
      @article.extended.should == 'bar<!--more-->baz'
    end

    it 'should be settable via self.attributes=' do
      @article.attributes = { :body_and_extended => 'foo<!--more-->bar' }
      @article.body.should == 'foo'
      @article.extended.should == 'bar'
    end
  end

  describe '#comment_url' do
    it 'should render complete url of comment' do
      contents(:article1).comment_url.should == "http://myblog.net/comments?article_id=#{contents(:article1).id}"
    end
  end

  describe '#preview_comment_url' do
    it 'should render complete url of comment' do
      contents(:article1).preview_comment_url.should == "http://myblog.net/comments/preview?article_id=#{contents(:article1).id}"
    end
  end

  it "test_can_ping_fresh_article_iff_it_allows_pings" do
    a = Article.find(contents(:article1).id)
    assert_equal(false, a.pings_closed?)
    a.allow_pings = false
    assert_equal(true, a.pings_closed?)
  end

  it "test_cannot_ping_old_article" do
    a = Article.find(contents(:article3).id)
    assert_equal(true, a.pings_closed?)
    a.allow_pings = false
    assert_equal(true, a.pings_closed?)
  end

  describe '#published_at_like' do
    before do
      # Note: these choices of times depend on no other articles within
      # these timeframes existing in test/fixtures/contents.yaml.
      # In particular, all articles there are from 2005 or earlier, which
      # is now more than two years ago, except for two, which are from
      # yesterday and the day before. The existence of those two makes
      # 1.month.ago not suitable, because yesterday can be last month.
      @article_two_month_ago = Factory(:article, :published_at => 2.month.ago)

      @article_four_months_ago = Factory(:article, :published_at => 4.month.ago)
      @article_2_four_months_ago = Factory(:article, :published_at => 4.month.ago)

      @article_two_year_ago = Factory(:article, :published_at => 2.year.ago)
      @article_2_two_year_ago = Factory(:article, :published_at => 2.year.ago)
    end

    it 'should return all content for the year if only year sent' do
      Article.published_at_like(2.year.ago.strftime('%Y')).map(&:id).sort.should == [@article_two_year_ago.id, @article_2_two_year_ago.id].sort
    end

    it 'should return all content for the month if year and month sent' do
      Article.published_at_like(4.month.ago.strftime('%Y-%m')).map(&:id).sort.should == [@article_four_months_ago.id, @article_2_four_months_ago.id].sort
    end

    it 'should return all content on this date if date send' do
      Article.published_at_like(2.month.ago.strftime('%Y-%m-%d')).map(&:id).sort.should == [@article_two_month_ago.id].sort
    end
  end

  describe '#has_child?' do
    it 'should be true if article has one to link it by parent_id' do
      Factory(:article, :parent_id => contents(:article1).id)
      contents(:article1).should be_has_child
    end
    it 'should be false if article has no article to link it by parent_id' do
      contents(:article1).should_not be_has_child
    end
  end

  describe 'self#last_draft(id)' do
    it 'should return article if no draft associated' do
      Article.last_draft(contents(:article1).id).should == contents(:article1)
    end
    it 'should return draft associated to this article if there are one' do
      draft = Factory(:article, :parent_id => contents(:article1).id, :state => 'draft')
      Article.last_draft(contents(:article1).id).should == draft
    end
  end
end
