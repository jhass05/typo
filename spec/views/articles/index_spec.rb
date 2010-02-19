require File.dirname(__FILE__) + '/../../spec_helper'

with_each_theme do |theme, view_path|
  describe "#{view_path}/articles/index" do
    before(:each) do
      @controller.view_paths.unshift(view_path) if theme
      # we only want to test pagination links
      ActionView::Base.class_eval do
        def article_links(article)
          ""
        end
        alias :category_links :article_links
        alias :tag_links :article_links
      end
    end

    context "normally" do
      before(:each) do
        @controller.action_name = "index"
        assigns[:articles] = Article.paginate(:all, :page => 2, :per_page => 4)
        render "articles/index"
      end

      it "should not have pagination link to page 2 without q param" do
        response.should_not have_tag("a[href=?]", "/page/2")
      end

      it "should have pagination link to page 1 without q param if on page 2" do
        response.should have_tag("a[href=?]", "/page/1")
      end

      it "should not have too many paragraph marks around body" do
        response.should have_tag("p", "body")
        response.should_not have_tag("p>p", "body")
      end

      it "should not have div nested inside p" do
	response.should_not have_tag("p>div")
      end
    end

    # *notice
    # this assumptions has "&amp;", i don`t know why, but we want only to test the q= param in link and have separated this test from controller
    context "when search" do
      before(:each) do
        @controller.action_name = "search"
        params[:q]           = "body"
        params[:page]        = 2
        params[:action]      = 'search'
        assigns[:articles] = Blog.default.articles_matching(params[:q], :page => 2, :per_page => 4)
        render "articles/index"
      end

      it "should not have pagination link to page 2 with q param" do
        response.should_not have_tag("a[href=?]", "/search/body?page=2") # *notice
      end

      it "should have pagination link to page 1 with q param if on page 2" do
        response.should have_tag("a[href=?]", "/search/body?page=1") # *notice
      end
    end
  end
end
