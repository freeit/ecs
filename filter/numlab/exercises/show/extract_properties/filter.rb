module Filter
  def self.start
    properties=FILTER_API.params[:properties]
    return if properties.nil?
    properties= properties.split(",")
    properties_length= properties.length
    obj= JSON.parse(FILTER_API.record.body)
    i=0
    body= ERB.new <<-'EOF',0,">"
{ "Exercise" :
  {
<% properties.each do |e| %>
<% i += 1 %>
  "<%= e %>" : "<%= obj["Exercise"][e] %>"<% if i!=properties_length %>,
<% end %>
<% end %>

  }
} 
EOF

    FILTER_API.record.body= body.result(binding)
    #Message.destroy_msg(FILTER_API.record)
  end
end
