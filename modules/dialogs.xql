xquery version "3.1";
(:~
: This module provides the functions that produce dialogs

: @author Christian Wittern  cwittern@yahoo.com
: @version 1.0
:)
module namespace dialogs="http://hxwd.org/dialogs"; 

import module namespace config="http://hxwd.org/config" at "../modules/config.xqm";
import module namespace functx="http://www.functx.com" at "../modules/functx.xql";
import module namespace tlslib="http://hxwd.org/lib" at "../modules/tlslib.xql";
(: import module namespace tlsapi="http://hxwd.org/tlsapi" at "../api/tlsapi.xql"; :)
import module namespace con='http://hxwd.org/con' at "../modules/concepts.xql"; 

declare namespace tei= "http://www.tei-c.org/ns/1.0";
declare namespace tls="http://hxwd.org/ns/1.0";
declare namespace tx = "http://exist-db.org/tls";

declare variable $dialogs:lmap := map{
"concept" : "Concepts",
"definition" : "Definition",
"notes" : "Criteria and general notes",
"old-chinese-criteria" : "Old Chinese Criteria",
"modern-chinese-criteria" : "Modern Chinese Criteria",
"tax-def" : map{
"taxonymy" : "Taxonymy",
"antonymy" : "Antonymy",
"hypernymy" : "Kind Of",
"see" : "See also"},
"source-references" : "Bibliography",
"warring-states-currency" : "Warring States Currency",
"register" : "Register",
"words" : "Words",
"none" : "Texts or Translation",
"old-chinese-contrasts" : "Old Chinese Contrasts",
"pointers" : "Pointers"
};

declare function dialogs:new-concept-dialog($options as map(*)){
 let $uuid := if (map:contains($options, "concept-id")) 
    then $options?concept-id else
    if (map:contains($options, "name")) then map:get($con:new-concepts($options?name), "id") else 
    "uuid-" || util:uuid()
   , $def := if ($uuid) then if (map:contains($con:new-concept-defs, $uuid)) then $con:new-concept-defs($uuid) else () else ()
   , $name := if(map:contains($options, "concept")) then $options?concept else ()
   return
   <div id="editSWLDialog" class="modal" tabindex="-1" role="dialog" style="display: none;">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header"><h5>Define a new concept: {$name}</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close" title="Close">x</button>
            </div>
            <div class="modal-body">
            <div class="form-row">
              <div id="input-def-group" class="col-md-6">
                    <label for="input-def" class="font-weight-bold">Definition </label>
                    <textarea id="input-def" class="form-control">{$def}</textarea>                   
              </div>
              <div id="select-name-group" class="form-group ui-widget col-md-6">
                 <label for="select-name" class="font-weight-bold">Alternate labels</label>
                 <small class="text-muted"><br/>Comma separated list of other names for this concept</small>
                 <input id="select-name" class="form-control" required="true" value="{$name}"></input>
                 <span id="name-id-span" style="display:none;">{$uuid}</span>
              </div>
            </div>
            <h6 class="font-weight-bold">Place of this concept within the ontology</h6>
            <div id="staging" style="display:none;" class="form-row">
              <div id="stag-taxonymy" class="col-md-3"><label class="font-weight-bold mr-3" for="stag-taxonymy">Taxonymy</label><span id="stag-taxonymy-span"></span></div>
              <div id="stag-antonymy"  class="col-md-3"><label  class="font-weight-bold  mr-3" for="stag-antonymy">Antonymy</label><span id="stag-antonymy-span"></span></div>
              <div id="stag-hypernymy"  class="col-md-3"><label  class="font-weight-bold  mr-3" for="stag-hypernymy">Kind Of</label><span id="stag-hypernymy-span"></span></div>
              <div id="stag-see"  class="col-md-3"><label  class="font-weight-bold  mr-3" for="stag-see">See also</label><span id="stag-see-span"></span></div>
            </div>
            <div class="form-row">
              <div id="select-tax-group" class="form-group col-md-4">
                <label for="select-tax">Type of relation: </label>
                 <select class="form-control" id="select-tax">
                  {for $l in map:keys($dialogs:lmap?tax-def)
                    order by $l
                    return
                    if ($l = "taxonymy") then
                    <option value="{$l}" selected="true">{$dialogs:lmap?tax-def($l)}</option>
                    else
                    <option value="{$l}">{$dialogs:lmap?tax-def($l)}</option>
                   } 
                 </select>                 
              </div>
              <div id="select-concept-group" class="form-group ui-widget col-md-4">
                 <label for="select-concept">Name of related concept: </label>
                 <input id="select-concept" class="form-control" required="true" value=""/>
                 <span id="concept-id-span" style="display:none;"></span>
                </div>
              <div class="form-group col-md-4">
                <label>Press here to add the concept</label>
                <button class="btn btn-primary" type="button" onclick="add_to_tax()" id="add-to-pointers">Add to ontology</button>
              </div>   
              </div>  
            <div class="form-row">
              <div id="input-crit-group" class="col-md-6">
                    <label for="input-crit" class="font-weight-bold">Old Chinese Criteria </label>
                    <textarea id="input-crit" class="form-control"></textarea>                   
              </div>
              <div id="input-notes-group" class="col-md-6">
                    <label for="input-notes" class="font-weight-bold">Notes</label>
                    <textarea id="input-notes" class="form-control"></textarea>                   
              </div>
            </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                <button type="button" class="btn btn-primary" onclick="save_new_concept('{$uuid}')">Save New Concept</button>
           </div>
         </div>
     </div>
</div>

};

declare function dialogs:review-swl-dialog($uuid as xs:string){
 let $swl := collection($config:tls-data-root || "/notes")//tls:ann[@xml:id=$uuid],
 (: "[M01]/[D01]/[Y0001] at [H01]:[m01]:[s01]" :)
 $seg-id:=$swl/parent::tei:seg/@xml:id,
 $creator-id := substring($swl/tls:metadata/@resp, 2),
 $score := if ($swl/tls:metadata/@score) then data($swl/tls:metadata/@score) else 0,
 $date := format-dateTime(xs:dateTime($swl/tls:metadata/@created),"[MNn] [D1o], [Y] at [h].[m01][Pn]"),
 $creator := doc("/db/apps/tls-data/vault/members.xml")//tei:person[@xml:id=$creator-id]
 return
 <div id="review-swl-dialog" class="modal" tabindex="-1" role="dialog" style="display: none;">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header"><h5>Review SWL <span class="pl-5">Current score: <span class="font-weight-bold">{$score}</span></span></h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close" title="Close">x</button>
            </div>
            <div class="modal-body">
            <h6 class="font-weight-bold">Existing SWL <small>created by {$creator//tei:persName/text()}, {$date}</small></h6>
            <div class="card-text">{tlslib:format-swl($swl, map{'type': 'row', 'context' : 'review'})}</div>
            <h6 class="font-weight-bold mt-2">Context</h6>
            {tlslib:get-text-preview($seg-id, map{"context" : 3, "format" : "plain"})}
            <!--
            <h6 class="font-weight-bold mt-2">Other possibilities</h6>
            <div class="form-row">
              <div id="select-synfunc-group" class="form-group ui-widget col-md-6">
                 <label for="select-synfunc">other syntactic function: </label>
                 <input id="select-synfunc" class="form-control" required="false" />
                 <span id="synfunc-id-span" style="display:none;"></span>
              </div>
              <div id="select-semfeat-group" class="form-group ui-widget col-md-6">
                  <label for="select-semfeat">other semantic feature: </label>
                  <input id="select-semfeat" class="form-control" />
                  <span id="semfeat-id-span" style="display:none;"></span>
              </div>
            </div> -->
            {if (count($swl/tls:metadata/tei:respStmt) > 1) then 
            <div>
            <h6 class="font-weight-bold mt-2">Previous comments</h6>
            {for $d in subsequence($swl/tls:metadata/tei:respStmt, 2) 
             let $cr2-id := $d/tei:name/text(),
             $action:= $d/tei:resp/text(),
             $cr2-date := format-dateTime(xs:dateTime($d/tei:resp/@notBefore),"[MNn] [D1o], [Y] at [h].[m01][Pn]"),
             $cr2 := doc("/db/apps/tls-data/vault/members.xml")//tei:person[@xml:id=$cr2-id]//tei:persName/text()
             return
             <p><span class="font-weight-bold" title="{$cr2}">@{$cr2-id}</span>({$cr2-date})-><span class="rp-5 {if ($action = 'approve') then 'bg-success' else if ($action = 'change') then 'bg-warning' else 'bg-danger'}">{$action}</span> &#160;&#160;<span class="bg-light">{$d/tei:note/text()}</span> </p>
}</div>
            else ()}
              <div id="select-concept-group" class="form-group ui-widget">
                    <label for="input-comment" class="font-weight-bold mt-2">Comment:<br/><small>If you want to suggest a different CONCEPT, vote for deletion here and create a new SWL.</small></label>
                    <textarea id="input-comment" class="form-control" required="false" value=""/>
              </div>
            <div>
            <div class="btn-group btn-group-toggle" data-toggle="buttons">
                <label class="btn btn-success active">
                    <input type="radio" name="actions" id="approve" autocomplete="off" checked="true">Approve</input>
                </label>
                <label class="btn btn-warning">
                    <input type="radio" name="actions" id="change" autocomplete="off"> Suggest changes</input>
                </label>
                <label class="btn btn-danger">
                    <input type="radio" name="actions" id="delete" autocomplete="off"> Mark for deletion</input>
                </label>
</div>            </div>  
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary" onclick="save_swl_review('{$uuid}')">Save Review</button>
           </div>
     </div>
     </div>
</div>
};


declare function dialogs:dialog-stub(){
<div id="dialog-stub" class="modal" tabindex="-1" role="dialog" style="display: none;">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header"><h5></h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close" title="Close">x</button>
            </div>
            <div class="modal-body">
            <h6 class="font-weight-bold"></h6>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                <button type="button" class="btn btn-primary" onclick="save_swl_review('{$uuid}')">Save</button>
           </div>
         </div>
     </div>
</div>
};

declare function dialogs:move-word($map as map(*)){
<div id="move-word-dialog" class="modal" tabindex="-1" role="dialog" style="display: none;">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header"><h5>Move {$map?word} to another concept</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close" title="Close">x</button>
            </div>
            <div class="modal-body">
            <h6 class="font-weight-bold">Select the target concept:</h6>
            <div>
                <span id="concept-id-span" style="display:none;"></span>
                <div id="select-concept-group" class="form-group ui-widget">
                    <input id="select-concept" class="form-control" required="true" value=""/>
                </div>
            <p>There are {$map?count} attributions, so this might take a while.</p>
            </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                <button type="button" class="btn btn-primary" onclick="do_move_word('{$map?word}', '{$map?wid}')">Move</button>
           </div>
         </div>
     </div>
</div>
};