/*
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
 */
/**
 * I contain the main functions for the log Analyzer plugin
 */
component hint="various rendering related files"{
	/**
	 * this function will be called to initalize
	 */
	public void function init(required struct lang, required string href) {
		variables.AssetHrefPath = listFirst(arguments.href,"?");
		variables.AssetHrefParams = listLast(arguments.href,"?");;
		variables.lang = arguments.lang;
	}

	public string function getCSRF(){
		return CSRFGenerateToken("log-analyzer");
	}

	private boolean function checkCSRF(required string token){
		if (not CSRFVerifyToken( arguments.token, "log-analyzer" ))
			throw message="access denied";
		else
			return true;
	}

	public void function includeCSS(required string template) {
		htmlhead text='<link rel="stylesheet" href="#variables.AssetHrefPath#?asset=#arguments.template#.css&#variables.AssetHrefParams#">#chr(10)#';
	}

	public void function includeJavascript(required string template) {
		htmlbody text='<script src="#variables.AssetHrefPath#?asset=#arguments.template#.js&#variables.AssetHrefParams#"></script>#chr(10)#';
	}

	public void function returnAsset(required string asset) {
		if (arguments.asset contains "..")
			throw "invalid asset request #htmleditformat(arguments.asset)#";
		local.fileType = listLast(arguments.asset, ".");

		switch (local.fileType){
			case "js":
				local.file = getDirectoryFromPath(getCurrentTemplatePath()) & "js/#arguments.asset#";
				local.mime = "text/javascript";
				break;
			case "css":
				local.file = getDirectoryFromPath(getCurrentTemplatePath()) & "css/#arguments.asset#";
				local.mime = "text/css";
				break;
			default:
				throw();
		}
		if (not fileExists(local.file)){
			header statuscode="404";
			writeOutput("file not found #htmleditformat(local.file)#");
			abort;
		}
		local.fileInfo = FileInfo(local.file);

		if ( structKeyExists(GetHttpRequestData().headers, "If-Modified-Since") ){
			local.if_modified_since=ParseDateTime(GetHttpRequestData().headers['If-Modified-Since']);
			if (DateDiff("s", local.fileInfo.dateLastModified, local.if_modified_since) GTE 0){
				header statuscode="304" statustext="Not Modified";
				abort;
			}
		}
		header name="cache-control" value="max-age=50000";
		header name="Last-Modified" value="#GetHttpTimeString(local.fileInfo.dateLastModified)#";
		content type="#local.mime#" reset="yes" file="#local.file#";
	}

	/**
	 * creates a text string indicating the timespan between NOW and given datetime
	 */
	public function getTextTimeSpan(required date date) output=false {
		var diffSecs = dateDiff('s', arguments.date, now());
		if ( diffSecs < 60 ) {
			return replace(variables.lang.Xsecondsago, '%1', diffSecs);
		} else if ( diffSecs < 3600 ) {
			return replace(variables.lang.Xminutesago, '%1', int(diffSecs/60));
		} else if ( diffSecs < 86400 ) {
			return replace(variables.lang.Xhoursago, '%1', int(diffSecs/3600));
		} else {
			return replace(variables.lang.Xdaysago, '%1', int(diffSecs/86400));
		}
	}

	public function cleanHtml( required string content){
		return ReReplace(arguments.content, "[\r\n]\s*([\r\n]|\Z)", Chr(10), "ALL")
	}

}