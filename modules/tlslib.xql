xquery version "3.1";
module namespace tlslib="http://hxwd.org/lib";

import module namespace config="http://hxwd.org/config" at "config.xqm";

import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "/db/apps/tei-publisher/modules/lib/util.xql";

declare namespace tei= "http://www.tei-c.org/ns/1.0";
declare namespace tls="http://hxwd.org/ns/1.0";

declare function tlslib:expath-descriptor() as element() {
    <rl/>
};

(: display $prec and $foll preceding and following segments of a given seg :)

declare function tlslib:displaychunk($targetseg as node(), $prec as xs:int?, $foll as xs:int?){

      let $fseg := if ($foll > 0) then subsequence($targetseg/following::tei:seg, 1, $foll) 
        else (),
      $pseg := if ($prec > 0) then subsequence($targetseg/preceding::tei:seg, 1, $prec) 
        else (),
      $head := $targetseg/ancestor::tei:div[1]/tei:head[1],
      $title := $targetseg/ancestor::tei:TEI//tei:titleStmt/tei:title/text(),
      $dseg := ($pseg, $targetseg, $fseg)
      return
      (
      <h1>{$title}</h1>,
      <h2>{$head/text()}</h2>,
       <button class="btn btn-primary" type="button" data-toggle="collapse" data-target=".swl">
            Show SWL
      </button>,
      <p>Debug: {$prec, $foll, sm:id()}</p>,
      <div id="chunkrow" class="row">
      <div id="chunkcol-left" class="col-sm-8">{for $d in $dseg return tlslib:displayseg($d, map{})}</div>
      <div id="chunkcol-right" class="col-sm-4">
<div id="swl-form" >
    <h2>New Attribution</h2>
    <form >
      <div class="form-group">
        <input type="hidden" id="swl-line-id"/>
        <span id="swl-line-id-span">Id of line</span>
      </div>
      <div class="form-group">
        <input type="hidden" id="swl-line-text"/>
        <span id="swl-line-text-span">Text of line</span>
      </div>
      <div class="form-group">
        <input  id="swl-query"/>
        <span id="swl-query-span">Word or char to annotate</span>
        <ul id="swl-select"></ul>
      </div>
        <input type="button" id="do-syn-func"/>
        <select id="syn-func-select"></select>
        <input type="text" id="x" />
    </form>
        <button onclick="get_sw()">Look for existing definitions</button>
</div>    
      </div>
      </div>,
      <div class="row">
      <div class="col-sm-2">
      {if ($dseg[1]/preceding::tei:seg[1]/@xml:id) then  
      (: currently the 0 is hardcoded -- do we need to make this customizable? :)
       <a href="?location={$dseg[1]/preceding::tei:seg[1]/@xml:id}&amp;prec={$foll+$prec}&amp;foll=0">Previous</a>
       else ()}
       </div>
       <div class="col-sm-2">
       {
       if ($dseg[last()]/following::tei:seg[1]/@xml:id) then
      <a href="?location={$dseg[last()]/following::tei:seg[1]/@xml:id}&amp;prec=0&amp;foll={$foll+$prec}">Next</a>
       else ()}
       </div> 
      </div>
      )

};
(:
<span class="en">{collection($config:tls-texts-root)//tei:seg[@corresp=concat('#', $seg/@xml:id)]/text()}</span>

:)

declare function tlslib:format-swl($node as node(), $type as xs:string?){
let $concept := data($node/@concept),
$zi := $node/tei:form[1]/tei:orth[1]/text(),
$py := $node/tei:form[1]/tei:pron[starts-with(@xml:lang, 'zh-Latn')]/text(),
$sf := $node//tls:syn-func,
$sm := $node//tls:sem-feat,
$def := $node//tei:def[1]
(:$pos := concat($sf, if ($sm) then (" ", $sm) else "")
:)
return
if ($type = "row") then
<div class="row">
<div class="col-sm-1">&#160;</div>
<div class="col-sm-2"><span class="zh">{$zi}</span> ({$py})</div>
<div class="col-sm-2"><a href="concept.html?concept={$concept}">{$concept}</a></div>
<div class="col-sm-6">
<span><a href="browse.html?type=syn-func&amp;id={data($sf/@corresp)}">{$sf/text()}</a>&#160;</span>
{if ($sm) then 
<span><a href="browse.html?type=sem-feat&amp;id={$sm/@corresp}">{$sm/text()}</a>&#160;</span> else ()}
{$def/text()}
</div>
</div>
else 
<li class="list-group-item" id="{$concept}">{$py} {$concept} {$sf} {$sm} {
if (string-length($def) > 10) then concat(substring($def, 10), "...") else $def}</li>
};


declare function tlslib:displayseg($seg as node()*, $options as map(*) ){
let $link := concat('#', $seg/@xml:id)
return
(<div class="row">
<div class="col-sm-3 zh" id="{$seg/@xml:id}">{$seg/text()}</div>　
<div class="col-sm-8 tr" id="{$seg/@xml:id}-tr">{collection($config:tls-data-root)//tei:seg[@corresp=$link]/text()}</div>
</div>,
<div class="row swl collapse" data-toggle="collapse">
<div class="col-sm-12">
{for $swl in collection($config:tls-data-root|| "/notes")//tls:srcline[@target=$link]
return
tlslib:format-swl($swl/ancestor::tls:swl, "row")}
</div>
</div>
)
};


declare function tlslib:getsynsem($type as xs:string, $string as xs:string, $map as map(*))
{
map:merge(
let $file := if ($type = "sem-feat") then "semantic-features.xml" else 
             if ($type = "syn-func") then "syntactic-functions.xml" else ""
   for $s in doc(concat($config:tls-data-root, '/core/', $file))//tei:head[contains(., $string)]
   return 
   map:entry(string($s/parent::tei:div/@xml:id), string($s))
 )
};

declare function tlslib:getwords($word as xs:string, $map as map(*))
{
map:merge(
   for $s in collection(concat($config:tls-data-root, '/concepts/'))//tei:orth[. = $word]
   return 
   map:entry(string($s/ancestor::tei:entry/@xml:id), (string($s/ancestor::tei:div/@xml:id), string($s/ancestor::tei:div/tei:head)))
 )
};


declare function tlslib:capitalize-first ( $arg as xs:string? )  as xs:string? {
   concat(upper-case(substring($arg,1,1)),
             substring($arg,2))
 } ;