# http://mislav.uniqpath.com/2010/09/cuking-it-right/
{
  'in the title' => 'h1, h2, h3',
  'in a button' => 'button, input[type=submit]',
  'in the navigation' => 'nav'
}.
each do |within, selector|
  Then /^(.+) #{within}$/ do |step|
    with_scope(selector) do
      Then step
    end
  end
end
