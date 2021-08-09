___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "OneTrust Consent Groups",
  "categories": ["ADVERTISING", "ANALYTICS", "MARKETING"],
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
    "displayName": "This vairable returns the consent groups accepted by the visitor to be used with tag triggers, for example."
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
    "help": "The output of the variable is a list of accepted consent groups. It be return either as a JS array or a comma joined string."
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
    "help": "Allows you to declare default groups which are on by default for new visitors. These are returned when there is no data yet in the dataLayer or in the cookie.\n\nAdd \"2\", for example, to set group 2 to be allowed by default."
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

/*
This template returns the consent groups that the visitor has selected.
It reads the cookie (OptanonConsent) set by OneTrust and also checks the dataLayer messages.
There is also a possibility to set default consent groups for situation where the dataLayer
or cookie information is not yet available.

Template by Taneli Salonen, Fluido.
*/

const log = require('logToConsole');
const getCookieValues = require('getCookieValues');
const copyFromDataLayer = require('copyFromDataLayer');

// return the value based on template radio button selection
function changeType(value) {
  if (data.outputType === 'string') {
    return value.join(',');
  }
  return value;
}

// first, try to access the values from the dataLayer
const consentDataLayer = copyFromDataLayer('OptanonActiveGroups');
if (typeof consentDataLayer === 'string' && consentDataLayer.length > 0) {
  const consentGroups = consentDataLayer.split(',').filter(function(group) {
    return group.length > 0;
  }).map(function(group) {
    return group + ':1';
  });
  
  return changeType(consentGroups);
}

// if dataLayer is not available, check the OptanonConsent cookie for consent groups
const consentCookie = getCookieValues('OptanonConsent', true)[0];
if (typeof consentCookie === 'string' && consentCookie.indexOf('groups=') > -1) {
  const groupsPart = consentCookie.split("&").filter(function(keyval) {
    // This is the part that stores the consent groups
    return keyval.indexOf("groups=") === 0;
  });
  
  if (groupsPart.length > 0) {
    const groupValue = groupsPart[0].split("=")[1];
    const consentGroupsArr = groupValue ? groupValue.split(",") : null;

    if (consentGroupsArr) {
      const consentGroups = consentGroupsArr.filter(function(group) {
         return group.split(':')[1] === '1';
      });
      if (consentGroups.length > 0) {
        return changeType(consentGroups);
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
  return changeType(consentGroups);
}

return changeType([]);


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
              },
              {
                "type": 1,
                "string": "test"
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
setup: ''


___NOTES___

Created on 8/9/2021, 10:08:50 AM


