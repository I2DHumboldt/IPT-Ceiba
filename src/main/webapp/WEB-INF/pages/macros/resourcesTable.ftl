<#--
resourcesTable macro: Generates a data table that has searching, pagination, and sortable columns.
- shownPublicly: Whether the table will be shown publicly, or only internally to managers
- numResourcesShown: The number of resources shown in the table
- sEmptyTable: The message shown when there are no resource records in the table
- columnToSortOn: The column to sort on by default (index starting at 0)
- sortOrder: The sort order of the columnToSortOn
-->
<#macro resourcesTable shownPublicly numResourcesShown sEmptyTable columnToSortOn sortOrder>
<script type="text/javascript" charset="utf-8">
    <#assign emptyString="--">
    <#assign dotDot="..">

    /* Sorts columns having "sType": "number". It should handle numbers with locale specific separators, e.g. 1,000 */
    jQuery.extend( jQuery.fn.dataTableExt.oSort, {
        "number-pre": function ( a )
        {
            var x = String(String(a).replace( /<[\s\S]*?>/g, "" )).replace( /,/g, '' );
            return parseFloat( x );
        },
        "number-asc": function ( a, b ) {
            return ((a < b) ? -1 : ((a > b) ? 1 : 0));
        },
        "number-desc": function ( a, b ) {
            return ((a < b) ? 1 : ((a > b) ? -1 : 0));
        }
    } );

    /* A cache variable to store data already retrieved from Elasticsearch. */ 
    var esCache = {};

    /* Determines whether a row must be in results set or not */
    $.fn.dataTableExt.afnFiltering.push( 
        function( settings, aData, dataIndex ) {
            var textSearch = $(".dataTables_filter input").val().trim(),
                response;
            if ( textSearch.length > 0 ){
                if ( esCache[textSearch.toLowerCase()] === undefined ){
                    console.log(textSearch + " NOT in cache! Weird, it should be there!!!");
                    return false;
                } else { // In cache, return it
                    response = esCache[textSearch.toLowerCase()];
                }
                
                // aData[0] has a URL containing the resource id, check if it's in the response array
                if ( response.indexOf(aData[0].split("?r=")[1].split("'")[0]) != -1 ){ 
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }
    );
    
    /* Search logic */
    var doSearch = function(){
        text = $(".dataTables_filter input").val().trim();
        if ( text.length > 0 ){ // At least a character to start searching 
            if ( esCache[text.toLowerCase()] === undefined ){
                // Not in cache, sending request to Elasticsearch.
                $.getJSON( "http://127.0.0.1:9200/ceiba/recurso/_search", { q:"\""+text+"\"", size:1000, _source:false } )
                    .done(function( json ) {
                        esCache[text.toLowerCase()] = $.map( json.hits.hits, function( value, index ) {return value._id;} );
                        $('#rtable').dataTable().fnDraw();
                    })  
                    .fail(function( jqxhr, textStatus, error ) {
                        var err = textStatus + ", " + error;
                        console.log( "Request Failed: " + err );
                });
            } else { // In cache, just go on...
                $('#rtable').dataTable().fnDraw();
            }
        }          
    };


    // parse a date in yyyy-mm-dd format
    function parseDate(input) {
            var parts = input.match(/(\d+)/g);
            return new Date(parts[0], parts[1]-1, parts[2], parts[3], parts[4], parts[5]); // months are 0-based
        }

    /* resources list */
    var aDataSet = [
      <#list resources as r>
          [<#if r.eml.logoUrl?has_content>'<img class="resourceminilogo" src="${r.eml.logoUrl}" />'<#else>'${emptyString}'</#if>,
           "<a href='${baseURL}<#if !shownPublicly>/manage</#if>/resource.do?r=${r.shortname}'><if><#if r.title?has_content>${r.title?replace("\'", "\\'")?replace("\"", '\\"')}<#else>${r.shortname}</#if></a>",
           <#if r.coreType?has_content && types[r.coreType?lower_case]?has_content>'${types[r.coreType?lower_case]?cap_first!}'<#else>'${emptyString}'</#if>,
           <#if r.subtype?has_content && datasetSubtypes[r.subtype?lower_case]?has_content >'${datasetSubtypes[r.subtype?lower_case]?cap_first!}'<#else>'${emptyString}'</#if>,
           '${r.recordsPublished!0}',
           '${r.modified?date}',
           <#if r.published>'${(r.lastPublished?date)!}'<#else>'<@s.text name="portal.home.not.published"/>'</#if>,
           '${(r.nextPublished?date?string("yyyy-MM-dd HH:mm:ss"))!'${emptyString}'}',
           <#if r.status=='PRIVATE'>'<@s.text name="manage.home.visible.private"/>'<#else>'<@s.text name="manage.home.visible.public"/>'</#if>,
           <#if r.creator??>'${r.creator.firstname?replace("\'", "\\'")?replace("\"", '\\"')!} ${r.creator.lastname?replace("\'", "\\'")?replace("\"", '\\"')!}'<#else>'${emptyString}'</#if>]<#if r_has_next>,</#if>
      </#list>
    ];

    $(document).ready(function($) {    
        $('#rtableContainer').html( '<table cellpadding="3" cellspacing="3" border="0" class="display" id="rtable"></table>' );
        $('#rtable').dataTable( {
            "aaData": aDataSet,
            "iDisplayLength": ${numResourcesShown},
            "bLengthChange": false,
            "bAutoWidth": false,
            "oLanguage": {
                "sEmptyTable": "<@s.text name="${sEmptyTable}"/>",
                "sZeroRecords": "<@s.text name="dataTables.sZeroRecords"/>",
                "sInfo": "<@s.text name="dataTables.sInfo"/>",
                "sInfoEmpty": "<@s.text name="dataTables.sInfoEmpty"/>",
                "sInfoFiltered": "<@s.text name="dataTables.sInfoFiltered"/>",
                "sSearch": "<@s.text name="manage.mapping.filter"/>:",
                "oPaginate": {
                    "sNext": "<@s.text name="pager.next"/>",
                    "sPrevious": "<@s.text name="pager.previous"/>"

                }
            },
            "aoColumns": [
                { "sTitle": "<@s.text name="portal.home.logo"/>", "bSearchable": false, "bVisible": false },
                { "sTitle": "<@s.text name="manage.home.name"/>"},
                { "sTitle": "<@s.text name="manage.home.type"/>"},
                { "sTitle": "<@s.text name="manage.home.subtype"/>"},
                { "sTitle": "<@s.text name="portal.home.records"/>", "bSearchable": false, "sType": "number"},
                { "sTitle": "<@s.text name="manage.home.last.modified"/>", "bSearchable": false},
                { "sTitle": "<@s.text name="manage.home.last.publication" />", "bSearchable": false},
                //{ "sTitle": "<@s.text name="manage.home.next.publication" />", "bSearchable": false},
                { "sTitle": "<@s.text name="manage.home.visible"/>", "bSearchable": false, "bVisible": <#if shownPublicly>false<#else>true</#if>},
                { "sTitle": "<@s.text name="portal.home.author"/>", "bVisible": <#if shownPublicly>false<#else>true</#if>}
            ],
            "aaSorting": [[ ${columnToSortOn}, "${sortOrder}" ]],
            "aoColumnDefs": [
                { 'bSortable': false, 'aTargets': [ 0 ] }
            ],
            "fnInitComplete": function(oSettings) {
                /* Next published date should never be before today's date, otherwise auto-publication must have failed.
                   In this case, highlight the row to bring the problem to the resource manager's attention. */
                var today = new Date();
                for ( var i=0, iLen=oSettings.aoData.length ; i<iLen ; i++ ) {
                  // warning fragile: index 7 must always equal next published date on both home page and manage page
                  // OJO, this index may vary when columns are added or remved!!!
                  var nextPublishedDate = (oSettings.aoData[i]._aData[7] == '${emptyString}') ? today : parseDate(oSettings.aoData[i]._aData[7]);
                  if (today > nextPublishedDate) {
                    oSettings.aoData[i].nTr.className += " rowInError";
                  }
                }
            }
        } );
        
        // Set tooltips
        $('#rtable thead th').each( function() {
          var  sTitle,
            sColumnTitle = this.textContent;
           
          if ( sColumnTitle == "<@s.text name="manage.home.name" />" )
              sTitle = "<@s.text name="manage.home.name.title" />";
          else if (sColumnTitle == "<@s.text name="manage.home.type" />")
            sTitle = "<@s.text name="manage.home.type.title" />";
          else if (sColumnTitle == "<@s.text name="manage.home.subtype" />")
            sTitle = "<@s.text name="manage.home.subtype.title" />";
          else if (sColumnTitle == "<@s.text name="portal.home.records" />")
            sTitle = "<@s.text name="portal.home.records.title" />";
          else if (sColumnTitle == "<@s.text name="manage.home.last.modified" />")
            sTitle = "<@s.text name="manage.home.last.modified.title" />";
          else if (sColumnTitle == "<@s.text name="manage.home.last.publication" />")
            sTitle = "<@s.text name="manage.home.last.publication.title" />";
          else if (sColumnTitle == "<@s.text name="manage.home.visible" />")
            sTitle = "<@s.text name="manage.home.visible.title" />";
          else if (sColumnTitle == "<@s.text name="portal.home.author" />")
            sTitle = "<@s.text name="portal.home.author.title" />";
          this.setAttribute( 'title', sTitle );
        } );
      
        // Set tooltip to filter text field
        $('#rtable_filter input')[0].setAttribute('title', "<@s.text name="manage.mapping.filter.title" />");
        
        // Tooltip initialization
        $('#rtable, #rtable_filter input').tooltip( {
          "delay": 100,
          //"track": true,
          "fade": 250,
          position: {
            my: "center bottom-20",
            at: "center top"
          }      
        } ).focus(function(evt) { // Avoid having the tooltip open on input focus 
          $(evt.currentTarget).tooltip("close").tooltip("disable");
        }).blur(function(evt) {
          $(evt.currentTarget).tooltip("enable");
        });
          
        // Event listener to search input
        var inputSearch = $(".dataTables_filter input"),
            text;
        inputSearch.unbind('keyup search input').bind('keyup', function(e) {
            if ( $(".dataTables_filter input").val().trim().length == 0 ){
                $('#rtable').dataTable().fnDraw();
            } else {
                if ( e.which == 13 ){
                    doSearch(); 
                }
            }
        });
      
        // Add a search button
        $("#rtable_filter label").append(
            '<button type="button" onclick="doSearch()" style="background-color:transparent; border:none; box-shadow:none; vertical-align: middle; margin-left:-5px;cursor: pointer;"><img src="${baseURL}/images/icons/announcement-grey.png" width="32px"/></button>'
        );
      
    } );
    
</script>
</#macro>
