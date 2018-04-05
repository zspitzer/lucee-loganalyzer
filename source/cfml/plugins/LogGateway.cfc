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
component hint="enumerate logs directories and lucee contexts" {

	/**
	 * this function will be called to initalize
	 */
	public void function init() {
		variables.logParser = new LogParser();
		variables.logDirectory = new LogDirectory();
	}
	/*
	public struct function analyzeLog(required string file, required string sort, required string sortDir){
		var log = getLogPath(arguments.file);
		return logParser.analyzeLog(log, arguments.sort, arguments.sortDir);
	}
	*/

	public string function getLogPath(string file="") output=false {
		return variables.logDirectory.getLogPath(arguments.file);
	}


	public query function getWebContexts() output=false {
		return variables.logDirectory.getWebContexts();
	}

	public string function getWebRootPathByWebID(required string webID) output=false {
		return variables.logDirectory.getWebRootPathByWebID(arguments.webID);
	}

	public query function readLog(required string file, any startDate) output=false {
		var log = logDirectory.getLogPath(arguments.file);
		var qLog = logDirectory.logParser.createLogQuery();
		var start = processDate(arguments.startDate);

		logParser.readLog(log, arguments.file, "", qLog, start);
		return qLog;
	}

	public query function listLogs(string sort="name", string dir="asc",
			any startDate="", string filter="", required boolean listOnly="true") output=false {
		return	variables.logDirectory.listLogs(argumentCollection=arguments);
	}

	public struct function getLog(string files, any startDate, numeric defaultDays=1,
		required boolean parseLogs, string search="") output=false {
		var start = logDirectory.processDate(arguments.startDate);
		var q_log = logParser.createLogQuery();
		var rows = 0;
		var st_files = {};
		var file_stats = {};
		var timings = [];
		var startTime = getTickCount();
		var q_log_files = logDirectory.listLogs(filter="*.log", listOnly=arguments.parseLogs);

		timings.append({
			name: "list-logs",
			metric: "enumerate",
			data:  getTickCount()-startTime
		});

		if (len(arguments.files) gt 0){
			var _files = listToArray(arguments.files); // avoid crash on single file
			for (var file in _files)
				st_files[file] = true;
		}
		//if (len(arguments.search) gt 0)
		//	defaultDays = 14;
		if (start eq false)
			start = logDirectory.getDefaultstart(q_log_files, st_files, defaultDays);

		loop query=q_log_files {
			if (start neq false){
				if (dateCompare(q_log_files.dateLastModified, start) eq -1)
					continue; // log file hasn't been updated start last request
			}
			if (structCount(st_files) gt 0
					and not structKeyExists(st_files, q_log_files.name))
				continue; // this file wasn't requested
			if (arguments.parseLogs){

				file_stats[q_log_files.name] = logParser.readLog(logPath=logDirectory.getLogPath(q_log_files.name),
					logName=q_log_files.name, context="", qLog=q_log, start=start, search=arguments.search);
				timings.append({
					name: q_log_files.name,
					metric: "parse",
					data:  file_stats[q_log_files.name].executionTime
				});
				// TODO cache file timings use them to avoid searching files which don't contain the search string
			}
			rows = q_log.recordcount;
		}

		QueryDeleteColumn( q_log_files, "TYPE");
		QueryDeleteColumn( q_log_files, "ATTRIBUTES");
		QueryDeleteColumn( q_log_files, "MODE");

		QuerySort( q_log, "logTimestamp", "desc");
		if (q_log.recordcount gt 500)
			q_log = QuerySlice(q_log, 1, min(500, q_log.recordcount ));

		//cflog(text="finished getLogs: #arguments.files# in #getTickCount()-startTimeLog#ms");
		// sort the logs from multiple sources by timestamp
		return {
			start: start,
			search: arguments.search,
			timings: timings,
			stats: file_stats,
			q_log: q_log,
			q_log_files: q_log_files,
			totalTime:  getTickCount()-startTime
		};
	}
}
