xquery version "3.1";

module namespace app="http://tls.kanripo.org/app";

declare namespace tei= "http://www.tei-c.org/ns/1.0";
declare namespace tls="http://tls.kanripo.org/ns/1.0";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://tls.kanripo.org/config" at "config.xqm";
import module namespace kwic="http://exist-db.org/xquery/kwic"
    at "resource:org/exist/xquery/lib/kwic.xql";

declare variable $app:SESSION := "tls:results";


(:~
 : This is a sample templating function. It will be called by the templating module if
 : it encounters an HTML element with an attribute: data-template="app:test" or class="app:test" (deprecated). 
 : The function has to take 2 default parameters. Additional parameters are automatically mapped to
 : any matching request or function parameter.
 : 
 : @param $node the HTML node with the attribute which triggered this call
 : @param $model a map containing arbitrary data - used to pass information between template calls
 :)
declare function app:test($node as node(), $model as map(*)) {
    <p>Dummy template output generated by function app:test at {current-dateTime()}. The templating
        function was triggered by the data-template attribute <code>data-template="app:test"</code>.</p>
};

declare function app:tls-summary($node as node(), $model as map(*)) {
(:let $tlsroot := $config:tls-data-root :)
<div>
{let $tlsroot := $config:tls-data-root
return
<p>
Dummy template {local-name($node), string($node), string($tlsroot), count(collection($tlsroot)//*:head)}
<table>
{for $a in collection($tlsroot)//tei:head
group by $key := $a/ancestor::tei:div/@type
order by $key
return
  <tr>
  <td>Key: {data($key)}</td>
  <td>Count: {count($a)}</td>
</tr>
}
</table>
</p>}
</div>
};

declare 
    %templates:wrap
function app:query($node as node()*, $model as map(*), $query as xs:string?, $mode as xs:string?)
{
    session:create(),
    let $hits := app:do-query($query, $mode)
    let $store := session:set-attribute($app:SESSION, $hits)
    return
       map:entry("hits", $hits)
};

declare function app:do-query($queryStr as xs:string?, $mode as xs:string?)
{
    let $query := app:create-query($queryStr, $mode)
    let $dataroot := "/db/apps/tls-data"   (: config:tls-data-root :)
    for $hit in collection($dataroot)//tei:div[ft:query(., $query)]
    order by ft:score($hit) descending
    return $hit
};

declare
    %templates:wrap
function app:from-session($node as node()*, $model as map(*)) {
    map:entry("hits", session:get-attribute($app:SESSION))
};



declare function app:create-query($queryStr as xs:string?, $mode as xs:string?)
{
<query>
    {
    if ($mode eq 'any') then 
        for $term in tokenize($queryStr, '\s')
        return
        <term occur="should">{$term}</term>
    else if ($mode eq 'all') then
        for $term in tokenize($queryStr, '\s')
        return
        <term occur="must">{$term}</term>
    else if ($mode eq 'phrase') then
        <phrase>{$queryStr}</phrase>
    else 
        <near>{$queryStr}</near>
    }
</query>
};

declare 
    %templates:default("start", 1)
    function app:show-hits($node as node()*, $model as map(*),$start as xs:int)
{
    for $hit at $p in subsequence($model("hits"), $start, 10)
    let $kwic := kwic:summarize($hit, <config width="40" table="yes"/>, app:filter#2)
    return
    <div class="tls-concept" xmlns="http://www.w3.org/1999/xhtml">
      <h3>{$hit/ancestor::tei:head/text()}</h3>
      <span class="number">{$start + $p - 1}</span>
      <table>{ $kwic }</table>
    </div>
};    


(:

declare
    %templates:default("start", 1)
    %templates:default("length", 10)
    function app:show-hits($node as node()*, $model as map()*,$start as xs:int, $length as xs:int)
{
    for $hit at $p in subsequence($model("hits"), $start, $length)
    let $kwic := kwic:summarize($hit, <config width="40" table="yes"/>, app:filter#2)
    return
    <div class="tls-concept" xmlns="http://www.w3.org/1999/xhtml">
      <h3>{$hit/ancestor::tei:head/text()}</h3>
      <span class="number">{$start + $p - 1}</span>
      <table>{ $kwic }</table>
    </div>
};
:)
declare %private function app:filter($node as node(), $mode as xs:string?) as text()?
{
    if ($mode eq 'before') then 
    text {concat($node, ' ') }
    else 
    text {concat(' ', $node) }
};

(: temporarily added the search code here to see if the search is working at all
 this should just be count($model("hits"))
:)
declare
    %templates:wrap
function app:hit-count($node as node()*, $model as map(*), $query as xs:string?) {
    let $hits := app:do-query($query, 'any')
    return
    (count($hits),
    <p>Model count: {count(session:get-attribute($app:SESSION))} <br/>Hits: {subsequence($hits, 1, 10)}</p>)
};




