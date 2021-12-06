xquery version "3.1";
(:~
: This module provides the functions for querying and displaying the bibliography
: of the TLS. 

: @author Christian Wittern  cwittern@gmail.com
: @version 1.0
:)
module namespace bib="http://hxwd.org/biblio";


declare namespace  mods="http://www.loc.gov/mods/v3";

import module namespace config="http://hxwd.org/config" at "config.xqm";
import module namespace tlslib="http://hxwd.org/lib" at "tlslib.xql";
import module namespace templates="http://exist-db.org/xquery/templates" ;



(:~ 
: Browse the bibliography
:)
declare function bib:browse-biblio($type as xs:string, $filterString as xs:string, $mode as xs:string?){
let $biblio := collection($config:tls-data-root || "/bibliography")
, $auth := $biblio//mods:mods/mods:name/mods:namePart[@type='family']
, $count := 0
, $acap := for $d in distinct-values(for $a in $auth return substring(normalize-space($a), 1, 1))
    order by $d
    where string-length($d) > 0
    return $d
, $aheader := for $c in $acap
return 
if ($c eq $filterString and $mode eq "author") then 
<a class="badge badge-pill badge-light" name="{$c}"><span>{$c}</span></a>
else
<a class="badge badge-pill badge-light" href="browse.html?type=biblio&amp;filter={$c}&amp;mode=author"><span>{$c}</span></a>
, $tit := $biblio//mods:title
, $tcap := for $d in distinct-values(for $a in $tit return substring(normalize-space($a), 1, 1))
    order by $d
    where string-length($d) > 0
    return $d
, $theader := for $c in $tcap
return 
if ($c eq $filterString and $mode eq "title") then 
<a class="badge badge-pill badge-light" name="{$c}"><span>{$c}</span></a>
else
<a class="badge badge-pill badge-light" href="browse.html?type=biblio&amp;filter={$c}&amp;mode=title"><span>{$c}</span></a>

, $top := for $d in distinct-values(for $t in $biblio//mods:note[@type='topics']  for $t1 in tokenize($t, ";") return normalize-space($t1))
    order by $d
    where string-length($d) > 0
    return $d
, $topcap := distinct-values(for $y in $top return substring($y, 1, 1))
, $topheader := for $c in $topcap
return 
if ($c eq $filterString and $mode eq "topic") then 
<a class="badge badge-pill badge-light" name="{$c}"><span>{$c}</span></a>
else
<a class="badge badge-pill badge-light" href="browse.html?type=biblio&amp;filter={$c}&amp;mode=topic"><span>{$c}</span></a>

return 
<div><h4>Browse the bibliography    </h4>

    <ul class="nav nav-tabs" id="Tab" role="tablist">
    <li class="nav-item"> <a class="nav-link" id="aut-tab" role="tab" 
    href="#byauthor" data-toggle="tab">Authors</a></li>
    <li class="nav-item"> <a class="nav-link" id="tit-tab" role="tab" 
    href="#bytitle" data-toggle="tab">Titles</a></li>
    <!--
    <li class="nav-item"> <a class="nav-link" id="top-tab" role="tab" 
    href="#bytopic" data-toggle="tab">Topics</a></li> -->
    </ul>
    <div class="tab-content" id="TabContent">    
    <div class="tab-pane" id="byauthor" role="tabpanel">    
    {$aheader}
    </div>
    <div class="tab-pane" id="bytitle" role="tabpanel">    
    {$theader}
    </div>
    <div class="tab-pane" id="bytopic" role="tabpanel">    
    {$topheader}
    </div>
    </div>
<div>
{if (string-length($filterString) > 0) then 
if ($mode eq "author") then
<div>{
for $b in $auth
 let $gn:= string-join($b/preceding-sibling::mods:namePart, '')
 where starts-with($b, $filterString)
 order by lower-case($b || $gn)
 return
 bib:biblio-short($b)
}</div>
else if ($mode eq "title") then 
<div>{
for $b in $tit
 where starts-with($b, $filterString)
 order by $b
 return
 bib:biblio-short($b)
}</div>
else 
()
else ()}
</div>

</div>
};

declare function bib:biblio-short($b) {
let $m:= $b/ancestor::mods:mods
return

<li><a href="bibliography.html?uuid={$m/@ID}"><span class="bold">{for $n in $m//mods:name return <span>{$n/mods:namePart[@type='family']}, {$n//mods:namePart[@type='given']};</span>}</span></a>　{string-join($m//mods:title/text(), " ")}, {$m//mods:dateIssued/text()}</li>
};

declare function bib:display-mods($uuid as xs:string){
let $biblio := collection($config:tls-data-root || "/bibliography")
,$m:=$biblio//mods:mods[@ID=$uuid]
return
<div>
<div class="row">
<div class="col-sm-2"/>
<div class="col-sm-2"><span class="bold">Responsibility</span></div>
<div class="col-sm-5">{for $a in $m/mods:name return (bib:display-authors($a), if (not ($a/last())) then ";" else ())}</div>
</div>
<div class="row">
<div class="col-sm-2"/>
<div class="col-sm-2"><span class="bold">Title</span></div>
<div class="col-sm-5">{for $t in $m/mods:titleInfo return bib:display-title($t)}</div>
</div>
<div class="row">
<div class="col-sm-2"/>
<div class="col-sm-2"><span class="bold">Details</span></div>
<div class="col-sm-5">(place){$m//mods:place/mods:placeTerm/text()}: (publisher){$m//mods:publisher/text()}, {$m//mods:dateIssued/text()}</div>
</div>
<div class="row">
<div class="col-sm-2"/>
<div class="col-sm-2"><span class="bold">Topics</span></div>
<div class="col-sm-5">{for $t in tokenize($m/mods:note[@type='topics'], ';') return <a href="browse.html?type=biblio&amp;filter={$t}&amp;mode=topic">{$t}</a>}</div>
</div>
  
</div>
};


declare function bib:display-authors($n as node()*){
 <span>{if (exists($n/mods:role)) then "(" || $n/mods:role/mods:roleTerm ||"): " else ()} {$n/mods:namePart[@type='family']}, {$n/mods:namePart[@type='given']}</span>
};

declare function bib:display-title($t as node()*){
 <span>{if (exists($t/@lang)) then "(" || data($t/@lang) ||"): " else ()} {$t/mods:title/text()} {$t/mods:subTitle/text()}</span>
};