___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "OneTrust Consent Groups",
  "categories": [
    "ADVERTISING",
    "ANALYTICS",
    "MARKETING"
  ],
  "description": "Returns the OneTrust (Optanon) consent groups. Can be used with setting up triggers for tags.",
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "LABEL",
    "name": "label1",
    "displayName": "This variable returns the consent groups accepted by the visitor to be used with tag triggers, for example."
  },
  {
    "type": "RADIO",
    "name": "returnType",
    "displayName": "Return type",
    "radioItems": [
      {
        "value": "all",
        "displayValue": "All consent groups"
      },
      {
        "value": "selected",
        "displayValue": "Selected consent group\u0027s status",
        "subParams": [
          {
            "type": "TEXT",
            "name": "selectedGroup",
            "displayName": "Selected individual group",
            "simpleValueType": true,
            "help": "For example \"C0002\""
          },
          {
            "type": "RADIO",
            "name": "individualConsentOutput",
            "displayName": "Return consent group status as",
            "radioItems": [
              {
                "value": "true_false",
                "displayValue": "\"false\" / \"true\"",
                "help": "Default \"true\" or \"false\""
              },
              {
                "value": "consent_mode",
                "displayValue": "\"denied\" / \"granted\"",
                "help": "GTM Consent Mode format"
              }
            ],
            "simpleValueType": true
          }
        ],
        "help": "Select an individual consent group to return its status as \"true\" or \"false\"."
      }
    ],
    "simpleValueType": true,
    "help": "Return either a list of all consent groups with their statuses or the status of an individual group. Default all.",
    "defaultValue": "all"
  },
  {
    "type": "RADIO",
    "name": "outputType",
    "displayName": "Variable Output Type",
    "radioItems": [
      {
        "value": "string",
        "displayValue": "String"
      },
      {
        "value": "array",
        "displayValue": "Array"
      }
    ],
    "simpleValueType": true,
    "help": "The output of the variable is a list of accepted consent groups. It can be returned either as a JS array or a comma joined string.",
    "enablingConditions": [
      {
        "paramName": "returnType",
        "paramValue": "all",
        "type": "EQUALS"
      }
    ]
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "defaultGroups",
    "displayName": "Default Groups",
    "simpleTableColumns": [
      {
        "defaultValue": "",
        "displayName": "Group",
        "name": "group",
        "type": "TEXT"
      }
    ],
    "newRowButtonText": "Add default group",
    "alwaysInSummary": true,
    "help": "Allows you to declare default groups which are on by default for new visitors. These are returned when there is no data yet in the dataLayer or in the cookie.\n\nAdd \"C0001\", for example, to set group C0001 to be allowed by default."
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

/*
This template returns the consent groups that the visitor has selected.
It reads the cookie (OptanonConsent) set by OneTrust and also checks the dataLayer messages.
There is also a possibility to set default consent groups for situation where the dataLayer
or cookie information is not yet available.

Template by Taneli Salonen.
*/

const log = require('logToConsole');
const getCookieValues = require('getCookieValues');
const copyFromDataLayer = require('copyFromDataLayer');

// return the value based on the selections in the template
function returnVariableValue(value) {
  const individualConsentReturnVal = {
    'true': data.individualConsentOutput === 'consent_mode' ? 'granted' : 'true',
    'false': data.individualConsentOutput === 'consent_mode' ? 'denied' : 'false'
  };
  
  // return only the selected groups status
  if (data.returnType === 'selected') {
    return value.filter(v => {
      return v.split(':')[0] === data.selectedGroup;
    }).length > 0 ? individualConsentReturnVal['true'] : individualConsentReturnVal['false'];
  }
  
  // return the full list as a string
  if (data.outputType === 'string') {
    return value.join(',');
  }
  
  // return the full list as an array
  return value;
}

// first, try to access the values from the dataLayer
const consentDataLayer = copyFromDataLayer('OptanonActiveGroups') || copyFromDataLayer('OnetrustActiveGroups');
if (typeof consentDataLayer === 'string' && consentDataLayer.length > 0) {
  
  const consentGroups = consentDataLayer.split(',').filter(function(group) {
    return group.length > 0;
  }).map(function(group) {
    return group + ':1';
  });
  
  // onetrust datalayer can return strings like ",,"
  if (consentGroups.length > 0) {
    return returnVariableValue(consentGroups);
  }
}

// if dataLayer is not available, check the OptanonConsent cookie for consent groups and other consent information
const consentCookie = getCookieValues('OptanonConsent', true)[0];
if (typeof consentCookie === 'string' && consentCookie.indexOf('groups=') > -1) {
  const groupsPart = consentCookie.split("&").filter(function(keyval) {
    // All of these are used to store consent information
    return keyval.indexOf("groups=") === 0 || keyval.indexOf("genVendors=") === 0 || keyval.indexOf("hosts=") === 0;
  });
  
  if (groupsPart.length > 0) {
    // join all consent data into one string
    const allGroups = groupsPart.map(part => {
      const groupData = part.split("=");
      return groupData[1] ? groupData[1] : '';
    }).join(',');
    
    const consentGroupsArr = allGroups ? allGroups.split(",") : null;

    if (consentGroupsArr) {
      const consentGroups = consentGroupsArr.filter(function(group) {
         return group.split(':')[1] === '1';
      });
      if (consentGroups.length > 0) {
        return returnVariableValue(consentGroups);
      }
    }
  }
}

// as a fallback, if neither the cookie nor dataLayer exist, return default consent groups listed in the template
// this can be the case when a new visitor has entered the site and OneTrust hasn't yet pushed the dataLayer message
const defaultGroups = data.defaultGroups;
if (defaultGroups && defaultGroups.length > 0) {
  const consentGroups = defaultGroups.map(function(group) {
    return group.group.split(':')[0] + ':1';
  });
  return returnVariableValue(consentGroups);
}

return returnVariableValue([]);


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "cookieAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "cookieNames",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "OptanonConsent"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_data_layer",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keyPatterns",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "OptanonActiveGroups"
              },
              {
                "type": 1,
                "string": "OnetrustActiveGroups"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: dataLayer is available
  code: |-
    const mockData = {
      outputType: 'string'
    };

    const log = require('logToConsole');

    mock('copyFromDataLayer', (dlName) => {
      return ",1,2,3";
    });

    // Call runCode to run the template's code.
    let variableResult = runCode(mockData);

    log(variableResult);

    const expectedResult = "1:1,2:1,3:1";

    // Verify that the variable result is as expected
    assertThat(variableResult).isEqualTo(expectedResult);
- name: cookie data available, no dataLayer
  code: |-
    const mockData = {
      outputType: 'string'
    };

    const log = require('logToConsole');

    mock('copyFromDataLayer', (dlName) => {
      return undefined;
    });

    mock('getCookieValues', (cookieName, decode) => {
      return ['isIABGlobal=false&datestamp=Mon+Aug+09+2021+08:27:26+GMT+0300+(Eastern+European+Summer+Time)&version=6.21.0&landingPath=NotLandingPage&groups=1:1,2:1'];
    });

    // Call runCode to run the template's code.
    let variableResult = runCode(mockData);

    log(variableResult);

    const expectedResult = "1:1,2:1";

    // Verify that the variable result is as expected
    assertThat(variableResult).isEqualTo(expectedResult);
- name: no dl, no cookie, only default fallback
  code: |-
    const mockData = {
      outputType: 'string',
      defaultGroups: [{group: '1'}]
    };

    const log = require('logToConsole');

    mock('copyFromDataLayer', (dlName) => {
      return undefined;
    });

    mock('getCookieValues', (cookieName, decode) => {
      return [];
    });

    // Call runCode to run the template's code.
    let variableResult = runCode(mockData);

    log(variableResult);

    const expectedResult = "1:1";

    // Verify that the variable result is as expected
    assertThat(variableResult).isEqualTo(expectedResult);
- name: no dl, no cookie, no default fallback
  code: |-
    const mockData = {
      outputType: 'string'
    };

    const log = require('logToConsole');

    mock('copyFromDataLayer', (dlName) => {
      return undefined;
    });

    mock('getCookieValues', (cookieName, decode) => {
      return [];
    });

    // Call runCode to run the template's code.
    let variableResult = runCode(mockData);

    log(variableResult);

    const expectedResult = "";

    // Verify that the variable result is as expected
    assertThat(variableResult).isEqualTo(expectedResult);
- name: dl with empty values, cookie available
  code: |-
    const mockData = {
      outputType: 'string'
    };

    const log = require('logToConsole');

    mock('copyFromDataLayer', (dlName) => {
      return ",,";
    });

    mock('getCookieValues', (cookieName, decode) => {
      return ['isIABGlobal=false&datestamp=Mon+Aug+09+2021+08:27:26+GMT+0300+(Eastern+European+Summer+Time)&version=6.21.0&landingPath=NotLandingPage&groups=1:1,2:1'];
    });

    // Call runCode to run the template's code.
    let variableResult = runCode(mockData);

    log(variableResult);

    const expectedResult = "1:1,2:1";

    // Verify that the variable result is as expected
    assertThat(variableResult).isEqualTo(expectedResult);
- name: return only the selected groups status
  code: |-
    const mockData = {
      outputType: 'string',
      returnType: 'selected',
      selectedGroup: 'C0002'
    };

    const log = require('logToConsole');

    mock('copyFromDataLayer', (dlName) => {
      return ",C0001,C0005,C0002,C0004,C0003,";
    });

    // Call runCode to run the template's code.
    let variableResult = runCode(mockData);

    log(variableResult);

    const expectedResult = "true";

    // Verify that the variable result is as expected
    assertThat(variableResult).isEqualTo(expectedResult);
- name: cookie data available, no dataLayer, return an array
  code: |-
    const mockData = {
      outputType: 'array'
    };

    const log = require('logToConsole');

    mock('copyFromDataLayer', (dlName) => {
      return undefined;
    });

    mock('getCookieValues', (cookieName, decode) => {
      return ['isIABGlobal=false&datestamp=Mon+Aug+09+2021+08:27:26+GMT+0300+(Eastern+European+Summer+Time)&version=6.21.0&landingPath=NotLandingPage&groups=1:1,2:1'];
    });

    // Call runCode to run the template's code.
    let variableResult = runCode(mockData);

    log(variableResult);

    const expectedResult = ["1:1","2:1"];

    // Verify that the variable result is as expected
    assertThat(variableResult).isEqualTo(expectedResult);
- name: OnetrustActiveGroups dataLayer
  code: |-
    const mockData = {
      outputType: 'string'
    };

    const log = require('logToConsole');

    mock('copyFromDataLayer', (dlName) => {
      if (dlName === 'OnetrustActiveGroups') {
        return ",1,2,3";
      }
      return undefined;
    });

    // Call runCode to run the template's code.
    let variableResult = runCode(mockData);

    log(variableResult);

    const expectedResult = "1:1,2:1,3:1";

    // Verify that the variable result is as expected
    assertThat(variableResult).isEqualTo(expectedResult);
setup: ''


___NOTES___

Created on 8/9/2021, 10:17:29 AM


