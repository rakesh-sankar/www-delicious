# 
# = WWW::Delicious
#
# Web service library for del.icio.us API
# 
#
# Category::   WWW
# Package::    WWW::Delicious
# Author::     Simone Carletti <weppos@weppos.net>
#
#--
# SVN: $Id$
#++


require File.dirname(__FILE__) + '/../helper'


class DeliciousTest < Test::Unit::TestCase
  include WWW::Delicious::TestCase
  
  def setup
    super
  end
  
  
  # =========================================================================
  # These tests check object constructor behavior 
  # =========================================================================
  
  def test_initialize
    obj = nil
    assert_nothing_raised() { obj = WWW::Delicious.new(TEST_USERNAME, TEST_PASSWORD) }
    assert_instance_of(WWW::Delicious, obj)
  end
  
  def test_initialize_with_block
    obj = instance do |delicious|
      assert_instance_of(WWW::Delicious, delicious)
    end
    assert_instance_of(WWW::Delicious, obj)
  end
  
  def test_initialize_with_options
    obj = nil
    assert_nothing_raised() { obj = WWW::Delicious.new(TEST_USERNAME, TEST_PASSWORD, {:user_agent => 'ruby/test'}) }
    assert_instance_of(WWW::Delicious, obj)
  end
  
  def test_initialize_raises_without_account
    assert_raise(ArgumentError) { WWW::Delicious.new() }
    assert_raise(ArgumentError) { WWW::Delicious.new(TEST_USERNAME) }
  end

  
  # =========================================================================
  # These tests check constructor options
  # =========================================================================
  
  def test_initialize_account
    obj = instance()
    assert_equal(@default_username, obj.username)
    assert_equal(@default_password, obj.password)
  end
  
  def test_initialize_option_user_agent
    obj = nil
    useragent = 'MyClass/1.0 (Foo/Bar +http://foo.com/)'
    assert_nothing_raised() { obj = instance(:user_agent => useragent) }
    assert_equal(useragent, obj.user_agent)
  end
  
  def test_initialize_option_user_agent_default
    useragent = instance.user_agent
    assert_match("Ruby/#{RUBY_VERSION}", useragent)
    assert_match("#{WWW::Delicious::NAME}/#{WWW::Delicious::VERSION}", useragent)
  end

  
  # =========================================================================
  # These tests check the low level HTTP request workflow
  # Even if #request is a protected method, it is so important that
  # we must test it separately as we did for a few other similar methods.
  # =========================================================================
  
  def test_request_raises_without_http_client
    obj = instance
    obj.http_client = nil
    assert_raise(WWW::Delicious::Error) { obj.send(:request, '/foo') }
  end
  
  def test_request_waits_necessary_time_between_requests
    # use valid_account? as a safe request to prevent tests 
    # run with invalid credential to fail
    
    obj = instance
    obj.valid_account? # 1st request
    s = Time.now
    3.times do |time|
      obj.valid_account? # N request
      e = Time.now
      diff = e - s
      assert(diff > WWW::Delicious::SECONDS_BEFORE_NEW_REQUEST)
      s = e # update last request for next loop
    end
  end

  
  def test_update
  end
  
  def test_parse_update_response
    instance.send(:parse_update_response, File.read(TESTCASE_PATH + '/update_success.xml'))
  end
  
  def test_parse_update_response_raises_without_update_root_node
    exception = assert_raise(WWW::Delicious::ResponseError) do
      instance.send(:parse_update_response, File.read(TESTCASE_PATH + '/bundles_all_success.xml'))
    end
    assert_match(/`update`/, exception.message)
  end
  
  
  def test_bundles_all
  end
  
  def test_parse_bundles_all_response
    response = instance.send(:parse_bundles_all_response, 
      File.read(TESTCASE_PATH + '/bundles_all_success.xml'))
    assert_instance_of(Array, response)
    assert_equal(2, response.length)
    
    results = [
      ['music', %w(ipod mp3 music)],
      ['pc', %w(computer software hardware)],
    ]
    
    response.each_with_index do |bundle, index|
      assert_instance_of(WWW::Delicious::Bundle, bundle)
      name, tags = results[index]
      assert_equal(name, bundle.name)
      assert_equal(tags, bundle.tags)
    end
  end
  
  def test_parse_bundles_all_response_empty
    response = instance.send(:parse_bundles_all_response, 
      File.read(TESTCASE_PATH + '/bundles_all_success_empty.xml'))
    assert_instance_of(Array, response)
    assert_equal(0, response.length)
  end
  
  def test_parse_bundles_all_response_without_bundles_root_node
    exception = assert_raise(WWW::Delicious::ResponseError) do
      instance.send(:parse_bundles_all_response, File.read(TESTCASE_PATH + '/update_success.xml'))
    end
    assert_match(/`bundles`/, exception.message)
  end
  
  
  def test_bundles_set
  end
  
  def test_parse_bundles_set_response
    assert_nothing_raised(Exception) { instance.send(:parse_bundles_set_response, 
      File.read(TESTCASE_PATH + '/bundles_set_success.xml')) }
  end
  
  def test_parse_bundles_set_response_without_result_root_node
    exception = assert_raise(WWW::Delicious::ResponseError) do
      instance.send(:parse_bundles_set_response, File.read(TESTCASE_PATH + '/update_success.xml'))
    end
    assert_match(/`result`/, exception.message)
  end
  
  
  def test_bundles_delete
  end
  
  def test_parse_bundles_delete_response
    assert_nothing_raised(Exception) { instance.send(:parse_bundles_delete_response, 
      File.read(TESTCASE_PATH + '/bundles_delete_success.xml')) }
  end
  
  def test_parse_bundles_delete_response_without_result_root_node
    exception = assert_raise(WWW::Delicious::ResponseError) do
      instance.send(:parse_bundles_delete_response, File.read(TESTCASE_PATH + '/update_success.xml'))
    end
    assert_match(/`result`/, exception.message)
  end
  
  
  def test_tags_get
  end
  
  def test_parse_tags_get_response
    response = instance.send(:parse_tags_get_response, 
      File.read(TESTCASE_PATH + '/tags_get_success.xml'))
    assert_instance_of(Array, response)
    assert_equal(2, response.length)
    
    results = [
      ['activedesktop', 1],
      ['business', 14],
    ]
    
    response.each_with_index do |tag, index|
      assert_instance_of(WWW::Delicious::Tag, tag)
      name, count = results[index]
      assert_equal(name, tag.name)
      assert_equal(count, tag.count)
    end
  end
  
  def test_parse_tags_get_response_empty
    response = instance.send(:parse_tags_get_response, 
      File.read(TESTCASE_PATH + '/tags_get_success_empty.xml'))
    assert_instance_of(Array, response)
    assert_equal(0, response.length)
  end
  
  def test_parse_tags_get_response_without_bundles_root_node
    exception = assert_raise(WWW::Delicious::ResponseError) do
      instance.send(:parse_tags_get_response, File.read(TESTCASE_PATH + '/update_success.xml'))
    end
    assert_match(/`tags`/, exception.message)
  end
  
  
  def test_tags_rename
  end
  
  def test_parse_tags_rename_response
    assert_nothing_raised(Exception) { instance.send(:parse_tags_rename_response, 
      File.read(TESTCASE_PATH + '/tags_rename_success.xml')) }
  end
  
  def test_parse_tags_rename_response_without_result_root_node
    exception = assert_raise(WWW::Delicious::ResponseError) do
      instance.send(:parse_tags_rename_response, File.read(TESTCASE_PATH + '/update_success.xml'))
    end
    assert_match(/`result`/, exception.message)
  end
  
  
end