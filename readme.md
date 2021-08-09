# OneTrust Consent Groups

This Google Tag Manager template returns the consent group values that the visitor has opted in to.

Functionality:
1. If the consent groups are already available in the dataLayer, return the values from there.
2. If the dataLayer message has not yet been pushed by OneTrust, read the OptanonConsent cookie and return the consent groups from there.
3. If neither the dataLayer nor the cookie is available (visitor first visit when OneTrust hasn't yet loaded), return a possible fallback default value that has been entered in the template. Otherwise return an empty value.

Output options:
A comma joined string or a JS array.

Usage:
Check if the variable value contains the desired group, for example "4:1". 4 is the number of the group and 1 means that it's active.