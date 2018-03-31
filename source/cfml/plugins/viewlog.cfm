<!---
 *
 * Copyright (c) 2016, Paul Klinkenberg, Utrecht, The Netherlands.
 * Originally written by Gert Franz, Switzerland.
 * All rights reserved.
 *
 * Date: 2016-02-11 13:45:05
 * Revision: 2.3.1.
 * Project info: http://www.lucee.nl/post.cfm/railo-admin-log-analyzer
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 --->
 <cfoutput>
	<!--- when viewing logs in the server admin, then a webID must be defined --->
	<cfif request.admintype eq "server">
		<cfparam name="session.loganalyzer.webID" default="" />
		<cfif not len(session.loganalyzer.webID)>
			<cfset var gotoUrl = rereplace(action('overview'), "^[[:space:]]+", "") />
			<cflocation url="#gotoUrl#" addtoken="no" />
		</cfif>
		<cfif session.loganalyzer.webID eq "serverContext">
			<cfoutput><h3>Server context log files</h3></cfoutput>
		<cfelse>
			<cfoutput><h3>Web context <em>#getWebRootPathByWebID(session.loganalyzer.webID)#</em></h3></cfoutput>
		</cfif>
	</cfif>

	<!--- to fix any problems with urlencoding etc. for logfile paths, we just use the filename of 'form.logfile'.
	The rest of the path is always recalculated anyway. --->
	<cfset url.logfile = listLast(url.file, "/\") />
	<cfset request.subTitle = "View  #htmleditformat(url.logfile)#">
	<div class="log-controls">
		<form action="#action('overview')#" method="post" class="log-actions">
			<input class="submit" type="submit" value="#arguments.lang.Back#" name="mainAction"/>
			<input class="expand-all button" type="button" value="Expand All" data-expanded="false"/>
			<input class="reload-logs button" type="button" value="Refresh"/>
			Search: <input type="text" class="search-logs" size="25">
		</form>

		<cfscript>
			param name="url.hidden"  default="";
			st_hidden = {};
			if (len(url.hidden) gt 0){
				var _hidden = ListToArray(url.hidden);
				for (var h in _hidden)
					st_hidden[h] = true;
			}
		</cfscript>

		<div class="log-severity-filter">
			<cfloop list="INFO,INFORMATION|WARN,WARNING|ERROR|FATAL|DEBUG|TRACE" index="severity" delimiters="|">
				<span class="log-severity-filter-type">
					<cfset sev = listFirst(severity,",")>
					<label class="log-severity-#sev#">
						#sev#
						<input type="checkbox" value="#sev#" <cfif not structKeyExists(st_hidden, sev)>checked</cfif>>
					</label>
				</span>
			</cfloop>
		</div>
	</div>
	<style class="log-severity-filter-css">
		<cfloop collection="#st_hidden#" item="h">
			.log-severity-#h#.log { display: none;}
		</cfloop>
	</style>
</cfoutput>

<div class="logs-error" style="display:none;"></div>
<cfset num=0/>
<cfset limit=5/>
<cfoutput>
	<div class="longwords logs" data-fetched="#DateTimeFormat(now(),"yyyy-mm-dd'T'HH:nn:ss")#">
</cfoutput>
	<cfscript>
		q_log = req.q_log;
	</cfscript>
	<cfsetting enablecfoutputonly="true">
	<cfloop query="q_log" maxrows=1000>
		<cfoutput><div class="log log-severity-#q_log.severity# #num mod 2 ? 'odd':''#" data-log="#num#"></cfoutput>
		<cfoutput><div class="log-header"><span class="log-fie">#q_log.logfile#</span></cfoutput>
		<cfoutput><span class="log-severity">#q_log.severity#</span></cfoutput>
		<cfoutput><span class="log-timestamp">#LSDateFormat(q_log.logtimestamp)# #LSTimeFormat(q_log.logtimestamp)#</span></cfoutput>
		<cfoutput></div></cfoutput>
		<cfoutput><div class="log-detail"></cfoutput>
		<cfset r = 1>
		<!---
		<cfdump var="#dump(queryGetRow(q_log, q_log.currentrow))#" expand="false">
		--->

		<cfoutput>#htmleditformat(q_log.log)#</cfoutput>
		<Cfif q_log.cfstack.len() gt 0>
			<cfset _stack = q_log.cfstack[currentrow]>
			<cfoutput><ul class="cfstack"></cfoutput>
			<Cfset maxrows =Min(ArrayLen(_stack),5)>
			<cfloop from="1" to="#maxrows#" index="s">
				<cfoutput><li>#_stack[s]#</li></cfoutput>
			</cfloop>
			<cfoutput></ul></cfoutput>
		</cfif>
		<Cfif len(q_log.stack) gt 0>
			<cfoutput><div style="display:none;" class="collapsed-log long-log-#num#"></cfoutput>
			<cfoutput>#htmleditformat(wrap(q_log.stack, 150))##chr(10)#</cfoutput>
			<cfoutput></div><a class="expand-log" data-log="#num#">click to expand</a></cfoutput>
		</cfif>
		<cfoutput></div><!---log-detail---></div><!---log---></cfoutput>
		<cfset num++ />
	</cfloop>
	<cfsetting enablecfoutputonly="false">
	</pre>
</div>
<cfoutput>
	<form action="#action('overview')#" method="post">
		<input class="submit" type="submit" value="#arguments.lang.Back#" name="mainAction"/>
	</form>
	#includeJavascript("viewlog")#
</cfoutput>
