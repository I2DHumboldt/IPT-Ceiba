<#escape x as x?html>
<#include "/WEB-INF/pages/inc/header.ftl">
	<title><#if "${newUser!}"=="no"><@s.text name="admin.user.title.edit"/><#else><@s.text name="admin.user.title.new"/></#if></title>
	<script type="text/javascript" src="${baseURL}/js/jconfirmation.jquery.js"></script>
<script type="text/javascript">

$(document).ready(function(){
	initHelp();
	$('.confirm').jConfirmAction({question : "<@s.text name="basic.confirm"/>", yesAnswer : "<@s.text name="basic.yes"/>", cancelAnswer : "<@s.text name="basic.no"/>"});
});   
</script>	
 <#assign currentMenu = "admin"/>
<#include "/WEB-INF/pages/inc/menu.ftl">
<#include "/WEB-INF/pages/macros/forms.ftl">
<div class="grid_21 suffix_3">

<h1><#if "${newUser!}"=="no"><@s.text name="admin.user.title.edit"/><#else><@s.text name="admin.user.title.new"/></#if></h1>
<@s.form id="newuser" cssClass="topForm half" action="user.do" method="post">
<p><@s.text name="admin.user.intro"/></p>
<p><@s.text name="admin.user.intro2"/></p>

	<@s.hidden name="id" value="${user.email!}" required="true"/>

	<@input name="user.email" disabled=id?has_content/>  
	<@input name="user.firstname" />  
	<@input name="user.lastname" />  
	<@select name="user.role" value=user.role javaGetter=false options={"User":"user.roles.user", "Manager":"user.roles.manager", "Publisher":"user.roles.publisher", "Admin":"user.roles.admin"}/>

	<#if "${newUser!}"=="no">
	  <div class="userPasswordButtons">
		<@label i18nkey="user.password">
			<@s.submit cssClass="button" name="resetPassword" key="button.resetPassword" />
		</@label>
	  </div>	
	<#else>
		<@input name="user.password" type="password" />
		<@input name="password2" i18nkey="user.password2" type="password"/>  
	</#if>
	
	</br></br>
	
	<select multiple="multiple" id="user.grantedAccessTo" name="user.grantedAccessTo">
	  <#if restrictedResources?has_content>
			<#list restrictedResources?sort_by("shortname") as rR>		
				<option value='${rR.shortname}'>${rR.shortname}</option> 
			</#list>
		</#if>
  </select>
  <script type="text/javascript" charset="utf-8">
  	$('#user\\.grantedAccessTo').multiSelect({
  		selectableHeader: "<div class='custom-header'><@s.text name="admin.user.restrictedResources" /></div>",
		  selectionHeader: "<div class='custom-header'><@s.text name="admin.user.grantAccessTo" /></div>"
  	});
  	$('#user\\.grantedAccessTo').multiSelect('select', [
  		<#if user.grantedAccessTo?has_content >
				${ "'"+user.grantedAccessTo?split(", ")?join("', '")+"'" } 
			</#if>
		]);  	
  </script>
  <div style="margin:auto; padding-top:10px; text-align: center;">
  <button type="button" cssClass="button" onClick="$('#user\\.grantedAccessTo').multiSelect('select_all');"><@s.text name="admin.user.grantAccessToAll" /></button>   
  <button type="button" cssClass="button" onClick="$('#user\\.grantedAccessTo').multiSelect('deselect_all');"><@s.text name="admin.user.removeAccessToAll" /></button>   
  </div>
  
  </br></br>
  <div class="userManageButtons">
 	<@s.submit cssClass="button" name="save" key="button.save"/>
 	<#if "${newUser!}"=="no"><@s.submit cssClass="confirm" name="delete" key="button.delete"/></#if>
 	<@s.submit cssClass="button" name="cancel" key="button.cancel"/>
  </div>	
  
</@s.form>
</div>

<#include "/WEB-INF/pages/inc/footer.ftl">
</#escape>