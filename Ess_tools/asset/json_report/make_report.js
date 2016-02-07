// --------------------------------  Functions  --------------------------------------
function makeIntoArray(variable){
	if (variable.constructor != Array){
		return Array(variable);
	}
	else return variable;
}

function countArrayValues(arr) { // returns two arrays, one unique values and the other counts for them.
	var a = [], b = [], prev;

	arr.sort();
	for ( var i = 0; i < arr.length; i++ ) {
		if ( arr[i] !== prev ) {
			a.push(arr[i]);
			b.push(1);
		} else {
			b[b.length-1]++;
		}
		prev = arr[i];
	}

	return {uniqueValues:a, counts:b};
}

function textFromItemsAndCounts(itemStrings, itemCounts, quantityString){
	var text = '';
	if (arguments.length<3)
	var quantityString = '';
	for (var n= 0; n < itemStrings.length;n++) {
		item = itemStrings[n];
		if (typeof(stringValue) != 'string')
		item = item.toString();
		text += item + ' (' + itemCounts[n].toString() + quantityString + ')';
		if (n<itemStrings.length - 1)
		text += ', ';
	}
	return text;
}

function isAvailable(stringValue) {
	return stringValue != 'NA' || stringValue != '-' || stringValue != ' ';
}

// -----------------------------------------------------------------------------

var level1Study = study.parentStudyObj.level1StudyObj;

// make key variables read from JSON to all be arrays.
level1Study.sessionTaskInfo = makeIntoArray(level1Study.sessionTaskInfo);
for (var i=0; i < level1Study.sessionTaskInfo.length; i++) {
	level1Study.sessionTaskInfo[i].dataRecording  = makeIntoArray(level1Study.sessionTaskInfo[i].dataRecording);
	level1Study.sessionTaskInfo[i].subject  = makeIntoArray(level1Study.sessionTaskInfo[i].subject);
}

level1Study.recordingParameterSet = makeIntoArray(level1Study.recordingParameterSet);
for (var k=0; k < level1Study.recordingParameterSet.length; k++){
	level1Study.recordingParameterSet[k].modality = makeIntoArray(level1Study.recordingParameterSet[k].modality);
}

var extracted = {}; // data extracted from study JSON object and sent to AngularJS (as $Scope)
extracted.level1 = {};
extracted.level2 = {};
extracted.levelDerived = {};
extracted.level1.shortDescription = level1Study.studyShortDescription;
extracted.level1.title = study.title;
extracted.level1.fullDescription = level1Study.studyDescription;
extracted.level1.showLevel1Notice = true;
extracted.level1.showLevel2Notice = false;
extracted.level1.showLevel3Notice = false;

extracted.level1.numberOfSessions = level1Study.sessionTaskInfo.length;

// count the number of subjects by looking at labIds. LabIds that are not provided,
//  i.e. are either NA or - are assumed to be unique.
var labsIds = [];
var groups = [];
for (var i=0; i < level1Study.sessionTaskInfo.length; i++) {
	for (var j=0; j < level1Study.sessionTaskInfo[i].subject.length; j++) {
		var labIdValue = level1Study.sessionTaskInfo[i].subject[j].labId;
		if (labIdValue == 'NA' || labIdValue == '-'){
			labIdValue = Math.floor((1 + Math.random()) * 0x1000000000000).toString();
		}
		labsIds[i] = labIdValue;
		groups.push(level1Study.sessionTaskInfo[i].subject[j].group);
	}
}

// look into recordingParameterSets associated with session records
var numberOfRecordingEEGChannels = [];
var modalitiesInDataRecording = []; // what modalities are in the data recording
var channelLocationTypes = [];
var dataRecording = [];
var eegSamplingFrequency = [];
for (var i=0; i < level1Study.sessionTaskInfo.length; i++){
	for (var j=0; j < level1Study.sessionTaskInfo[i].dataRecording.length; j++){
		var parameterSetLabel = level1Study.sessionTaskInfo[i].dataRecording[j].recordingParameterSetLabel;
		for (var k=0; k < level1Study.recordingParameterSet.length; k++){
			if (level1Study.recordingParameterSet[k].recordingParameterSetLabel == parameterSetLabel){
				var modalitiesInParamerSet = [];
				var  modalityNumberOfChannels = [];
				for (var m=0; m < level1Study.recordingParameterSet[k].modality.length; m++){
					modalitiesInParamerSet.push(level1Study.recordingParameterSet[k].modality[m].type);
					var numberOfChannels = 1 + parseInt(level1Study.recordingParameterSet[k].modality[m].endChannel) - parseInt(level1Study.recordingParameterSet[k].modality[m].startChannel);
					modalityNumberOfChannels.push(numberOfChannels);
					if (level1Study.recordingParameterSet[k].modality[m].type.toUpperCase() == 'EEG'){
						numberOfRecordingEEGChannels.push (numberOfChannels);
						// using th length of dataRecording as a proxy for the numberof data recordings so far
						eegSamplingFrequency[dataRecording.length] = level1Study.recordingParameterSet[k].modality[m].samplingRate;
						channelLocationTypes[dataRecording.length] = level1Study.recordingParameterSet[k].modality[m].channelLocationType;
					}
				}
				modalitiesInDataRecording = modalitiesInDataRecording.concat(_.uniq(modalitiesInParamerSet));
			}

		}

		// create text, listing modalities with their number of channels in paranthesis
		modalitiesAndTheirChannelsText = textFromItemsAndCounts(modalitiesInParamerSet, modalityNumberOfChannels);

		dataRecording.push({
			'sessionNumber': level1Study.sessionTaskInfo[i].sessionNumber,
			'taskLabel': level1Study.sessionTaskInfo[i].taskLabel,
			'sessionLabId': level1Study.sessionTaskInfo[i].labId,
			'channelLocationsFilename': level1Study.sessionTaskInfo[i].subject[0].channelLocations,
			'subjectGroup': level1Study.sessionTaskInfo[i].subject[0].group,
			'subjectGender': level1Study.sessionTaskInfo[i].subject[0].gender,
			'subjectYOB': level1Study.sessionTaskInfo[i].subject[0].YOB,
			'subjectAge': level1Study.sessionTaskInfo[i].subject[0].age,
			'subjectLabId': level1Study.sessionTaskInfo[i].subject[0].labId,
			'subjectHandedness': level1Study.sessionTaskInfo[i].subject[0].hand,
			'filename': level1Study.sessionTaskInfo[i].dataRecording[j].filename,
			'eventInstanceFile': level1Study.sessionTaskInfo[i].dataRecording[j].eventInstanceFile,
			'originalFileNameAndPath': level1Study.sessionTaskInfo[i].dataRecording[j].originalFileNameAndPath,
			'modalitiesAndTheirChannelsText': modalitiesAndTheirChannelsText,
			'eegSamplingFrequency': eegSamplingFrequency[channelLocationTypes.length-1]
		})
	}
}

extracted.level1.numberOfSubjects = _.uniq(labsIds).length;
extracted.level1.subjectGroup = _.uniq(groups).toString();
extracted.level1.eventSpecificiationMethod =  level1Study.eventSpecificiationMethod;

// count the number of recordings that the same number of channels
var result = countArrayValues(numberOfRecordingEEGChannels);
var uniqueEEGChannelNumbers = result.uniqueValues;
var numberOfRecordingsWithChannelNumber = result.counts;

// form the string that contains number of EEG channels and the number of data recordings associated with each (in parenthesis)
extracted.level1.numberOfChannels = textFromItemsAndCounts(uniqueEEGChannelNumbers, numberOfRecordingsWithChannelNumber, ' recordings')

// count the number of recordings that the same number of channels
var result = countArrayValues(modalitiesInDataRecording);
var uniqueModalities = result.uniqueValues;
var numberOfRecordingsWithModality = result.counts;


// form the string that contains different modalities and the number of data recordings associated with each (in parenthesis)
extracted.level1.modalities = textFromItemsAndCounts(uniqueModalities, numberOfRecordingsWithModality, ' recordings')

var result = countArrayValues(channelLocationTypes);
extracted.level1.channelLocationTypes = textFromItemsAndCounts(result.uniqueValues, result.counts, ' recordings');

extracted.level1.totalSize = level1Study.summaryInfo.totalSize;
extracted.level1.licenseType = level1Study.summaryInfo.license.type;
extracted.level1.fundingOrganization = level1Study.projectInfo.organization;

// Publications
//level1Study.publicationsInfo =[{'citation': 'some citation 1', 'link': 'http://google.com', 'DOI': 'w5745874584854'},{'citation': 'some citation 2', 'link': '', 'DOI': 'gzsgsg'}];

level1Study.publicationsInfo = makeIntoArray(level1Study.publicationsInfo);
extracted.level1.publications = [];
for (var i=0; i < level1Study.publicationsInfo.length; i++){
	var text = level1Study.publicationsInfo[i].citation;
	var link = level1Study.publicationsInfo[i].link;
	if (level1Study.publicationsInfo[i].DOI != ''){
		text = text + ', DOI: ' + level1Study.publicationsInfo[i].DOI;
		if (link == ''){
			link = 'http://dx.doi.org/' + level1Study.publicationsInfo[i].DOI;
		}
	}
	extracted.level1.publications[i]= {'text': text, 'link':link};
}
// hide publications section when informationis not available
extracted.level1.showPublications = extracted.level1.publications.length != 1 || extracted.level1.publications[0].text != '';

// experimenters
level1Study.experimentersInfo = makeIntoArray(level1Study.experimentersInfo);
extracted.level1.experimenters = [];
for (var i=0; i < level1Study.experimentersInfo.length; i++){
	var text = level1Study.experimentersInfo[i].name;
	var role = level1Study.experimentersInfo[i].role;
	if (role != ''){
		text = role + ': ' + text;
		extracted.level1.experimenters.push(text);
	}
}

// point of contact
// show the section if it is specified.
extracted.level1.showlevel1PointOfContact = level1Study.contactInfo.email != '' || level1Study.contactInfo.email != '-' || level1Study.contactInfo.email != '-';
extracted.level1.level1PointOfContact = '';
if (isAvailable(level1Study.contactInfo.name)){
	extracted.level1.level1PointOfContact = level1Study.contactInfo.name;
}

if (extracted.level1.level1PointOfContact !=''){
	extracted.level1.level1PointOfContact += ', ';
}
extracted.level1.level1PointOfContact += 'Email: ' + level1Study.contactInfo.email;

if (extracted.level1.level1PointOfContact !=''){
	extracted.level1.level1PointOfContact += ', ';
}
if (extracted.level1.level1PointOfContact !='' && isAvailable(level1Study.contactInfo.phone)){
	extracted.level1.level1PointOfContact += 'Phone: ' + level1Study.contactInfo.phone;
}


// hide publications section when informationis not available
extracted.level1.showExperimenters = extracted.level1.experimenters.length != 1 || extracted.level1.experimenters[0] != '';
extracted.level1.rootURI = level1Study.rootURI;
if (extracted.level1.rootURI == '.') // make it proper relative link
	extracted.level1.rootURI = '..';

var level1DataRecordingsColumnDefs = [
	{headerName: "Session", field: "sessionNumber", minWidth: 100, width:100, pinned: true, checkboxSelection: false},
	{headerName: "Task", field: "taskLabel", minWidth: 100, width:100, pinned: true},
	{headerName: "EEG Sampling Rate (Hz)", field: "eegSamplingFrequency", minWidth: 200, width:200},
	{headerName: "Modalities (number of channels)", field: "modalitiesAndTheirChannelsText", minWidth: 250, width:250},
	{headerName: "Session Lab Id", field: "sessionLabId", minWidth: 150, width:150},
	{headerName: "Notes", field: "notes", minWidth: 100, width:100},
	{headerName: "Filename", field: "filename", minWidth: 300, width:300,
	template: '<a href="' + extracted.level1.rootURI + '/session/{{data.sessionNumber}}/{{data.filename}}""><span ng-bind="data.filename"></span></a>'},
	{headerName: "Original Filename", field: "originalFileNameAndPath", minWidth: 100, width:300},
	{headerName: "Channel Locations", field: "channelLocationsFilename", minWidth: 100, width:300,
template: '<a href="' + extracted.level1.rootURI + '/session/{{data.sessionNumber}}/{{data.channelLocationsFilename}}""><span ng-bind="data.channelLocationsFilename"></span></a>'},
	{headerName: "Subject", cellStyle:{textAlign: 'center', color: 'red'},  children: [
		{headerName: "Group", field: "subjectGroup", minWidth: 80, width:80},
		{headerName: "Gender", field: "subjectGender", minWidth: 100, width:100},
		{headerName: "YOB", field: "subjectYOB", minWidth: 100, width:100},
		{headerName: "Age", field: "subjectAge", minWidth: 70, width:70},
		{headerName: "Handedness", field: "subjectHandedness", minWidth: 130, width:130},
		{headerName: "Lab Id", field: "subjectLabId", minWidth: 130, width:130}
	]},
];


function autoSizeAllGridColumns() {
	var allColumnIds = [];
	level1DataRecordingsColumnDefs.forEach( function(columnDef) {
		allColumnIds.push(columnDef.field);
		if (columnDef.children)
		for (var i = 0; i < columnDef.children.length; i++) {
			allColumnIds.push(columnDef.children[i].field);
		}
	});
	extracted.level1.level1DataRecordingsGridOptions.columnApi.autoSizeColumns(allColumnIds);
}

function whenLevel1DataRecordingsGridIsReady (event){
	autoSizeAllGridColumns();
	// do it again in 1 second so Angular ha time to dynamically render all filenames
	setTimeout(autoSizeAllGridColumns, 1000);
}

extracted.level1.level1DataRecordingsGridOptions = {
	columnDefs: level1DataRecordingsColumnDefs,
	rowData: dataRecording,
	enableColResize: true,
	enableSorting: true,
	//	unSortIcon: true,
	enableFilter: true,
	suppressMenuHide: true,
	angularCompileRows: true, // for template
	onReady: whenLevel1DataRecordingsGridIsReady
};
// without this if there is only one row it becomes hidden.
if (extracted.level1.level1DataRecordingsGridOptions.rowData.length == 1){
	extracted.level1.level1DataRecordingsGridOptions.rowHeight = 50;
}


// run the grid filter only when there was not a chage of value right before it.
// this is to prevent stuttering.

var lastTimeLevel1DatarecordingsFilterChanged = new Date();

function filterLevel1DataRecordingsIfNoChange(value) {
	var thisTime = new Date();
	if (thisTime.getTime() - lastTimeLevel1DatarecordingsFilterChanged.getTime() > 200){
		extracted.level1.level1DataRecordingsGridOptions.api.setQuickFilter(value);
	}
}

function onLevel1DataRecordingsFilterChanged(value) {
	lastTimeLevel1DatarecordingsFilterChanged = new Date();
	setTimeout(filterLevel1DataRecordingsIfNoChange, 300, value);
}

// task grid
var level1TasksColumnDefs = [
	{headerName: "Task Label", field: "taskLabel", minWidth: 200, width:200},
	{headerName: "Description", field: "description", minWidth: 400, width:400},
	{headerName: "HED Tags", field: "tag", minWidth: 400, width:400}
];


extracted.level1.level1TasksGridOptions = {
	columnDefs: level1TasksColumnDefs,
	rowData:makeIntoArray(level1Study.tasksInfo),
	enableColResize: true,
	enableSorting: true,
	enableFilter: true,
};
// without this if there is only one row it becomes hidden.
if (extracted.level1.level1TasksGridOptions.rowData.length == 1){
	extracted.level1.level1TasksGridOptions.rowHeight = 50;
}

// Events grid
var level1EventsColumnDefs = [
	{headerName: "Event Code", field: "code", minWidth: 200, width:200, pinned: true},
	{headerName: "Label", field: "label", minWidth: 400, width:400},
	{headerName: "Description", field: "description", minWidth: 200, width:500, cellStyle: {'white-space': 'pre-wrap'}},
	{headerName: "HED Tags", field: "tag", minWidth:2300, width:600,cellStyle: {'white-space': 'pre-wrap'}}
];

level1Study.eventCodesInfo = makeIntoArray(level1Study.eventCodesInfo);
var eventData = [];
for (var i = 0; i < level1Study.eventCodesInfo.length; i++) {
	level1Study.eventCodesInfo[i].condition = makeIntoArray(level1Study.eventCodesInfo[i].condition);
	for (var j = 0; j < level1Study.eventCodesInfo[i].condition.length; j++) {
		eventData.push({
			code: level1Study.eventCodesInfo[i].code,
			label: level1Study.eventCodesInfo[i].condition[j].label,
			description: level1Study.eventCodesInfo[i].condition[j].description,
			tag: level1Study.eventCodesInfo[i].condition[j].tag
		});
	}
}


var lastTimeLevel1EventsFilterChanged = new Date();

function filterLevel1EventsIfNoChange(value) {
	var thisTime = new Date();
	if (thisTime.getTime() - lastTimeLevel1EventsFilterChanged.getTime() > 200){
		extracted.level1.level1EventsGridOptions.api.setQuickFilter(value);
	}
}

function onLevelEventsFilterChanged(value) {
	lastTimeLevel1DatarecordingsFilterChanged = new Date();
	setTimeout(filterLevel1EventsIfNoChange, 300, value);
}

extracted.level1.level1EventsGridOptions = {
	columnDefs: level1EventsColumnDefs,
	rowData:eventData,
	enableColResize: true,
	enableSorting: true,
	enableFilter: true,
	suppressMenuHide: true,
	rowHeight: 60
};

//license section
extracted.level1.showLevel1LicensePart = isAvailable(level1Study.summaryInfo.license.link) ||  isAvailable(level1Study.summaryInfo.license.type) ||  isAvailable(level1Study.summaryInfo.license.text);
extracted.level1.level1LicenseType = level1Study.summaryInfo.license.type;
extracted.level1.showLevel1LicenseLink = isAvailable(level1Study.summaryInfo.license.link);
extracted.level1.level1LicenseLink = level1Study.summaryInfo.license.link;
extracted.level1.showLevel1LicenseText = isAvailable(level1Study.summaryInfo.license.text);
extracted.level1.level1LicenseText = level1Study.summaryInfo.license.text;

// IRB section
extracted.level1.showIRBPart = isAvailable(level1Study.irbInfo);
extracted.level1.IRBtext = level1Study.irbInfo;

// copyright section
extracted.level1.showLevel1CopyRight = isAvailable(level1Study.copyrightInfo);
extracted.level1.copyrightText  = level1Study.copyrightInfo;

//---------------------- setting up AngularJS ----------------------------------

angular.module('essReportApp',  ["agGrid"]).controller('ReportController', function($scope) {
	// transfer key values from extracted to $scope so they are placed in the html template
	for (var key in extracted) {
		// skip loop if the property is from prototype
		if (!extracted.hasOwnProperty(key)) continue;
		$scope[key] = extracted[key];
	}
});
