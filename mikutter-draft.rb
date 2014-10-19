#-*- coding: utf-8 -*-
#
# * mikutter-drafts.rb
# 
# postboxに書きかけたツイートを保存するプラグイン．
# - 書きかけツイートの追加・削除機能
# - 「前の下書きへ」コマンドで順に下書きを呼び出します.ショートカットキーを指定して使います.
#

require 'pstore'

Plugin.create :drafts do

  def drafts_init
    @i = 0
    @stack = ""
    @@drafts = PStore.new(File.expand_path(File.join(File.dirname(__FILE__), "drafts.db")))
    @@drafts.transaction do
      unless @@drafts.roots
        @@drafts[:list] = []
      end
    end

  end

  def add_draft(text)
    @@drafts.transaction do
      @@drafts[:list] << text
      @@drafts[:list] = @@drafts[:list].uniq
    end
    Plugin.call(:update, nil, [Message.new(:message => "下書きに 「" + text + "」 を追加しました", :system => true)])
  end

  def del_draft(text)
    @@drafts.transaction do
      @@drafts[:list] = @@drafts[:list].reject!{|line| line == text }
    end
    Plugin.call(:update, nil, [Message.new(:message => "下書きに 「" + text + "」 を削除しました", :system => true)])
  end

  def pick_draft(text)
    lines = ""
    @@drafts.transaction do
      lines = @@drafts[:list]
    end

    if @i < 1 || lines.size == 0
      @i = 0
      picked = @stack
    elsif @i > lines.size
      @i = lines.size
      picked = lines[lines.size - @i]
    else
      picked = lines[lines.size - @i]
    end
  

    picked
  end
 
  drafts_init
  @@drafts.transaction do
    if @@drafts[:list] == nil
      @@drafts[:list] = []
    end
  end

  command(:save_draft,
          name: '下書きに保存',
          condition: lambda{ |opt| true},
          visible: true,
          icon: File.expand_path(File.join(File.dirname(__FILE__), "memo.png")),
          role: :postbox) do |opt|
            add_draft(Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text)
            Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text = ""
          end
  command(:remove_draft,
          name: '下書きから削除',
          condition: lambda{ |opt| true},
          visible: true,
          icon: File.expand_path(File.join(File.dirname(__FILE__), "memo.png")),
          role: :postbox) do |opt|
            del_draft(Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text)
            Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text = ""
  end
  command(:shift_draft,
          name: '次の下書きへ',
          condition: lambda{ |opt| true},
          visible: false,
          icon: File.expand_path(File.join(File.dirname(__FILE__), "memo.png")),
          role: :postbox) do |opt|
            if @i == 0
              @stack = Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text
            end
            @i -= 1
            Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text =
              pick_draft(Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text)
  end
  command(:pop_draft,
          name: '前の下書きへ',
          condition: lambda{ |opt| true},
          visible: false,
          icon: File.expand_path(File.join(File.dirname(__FILE__), "memo.png")),
          role: :postbox) do |opt|
            if @i == 0
              @stack = Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text
            end
           @i += 1 
           Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text =
             pick_draft(Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text)
  end
end
