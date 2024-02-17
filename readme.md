# OneTrust Consent Groups

This Google Tag Manager template returns the consent group values that the visitor has opted in to.

Functionality:
1. If the consent groups are already available in the global variables, return the values from there.
2. If the consent groups are already available in the dataLayer, return the values from there.
3. If the dataLayer message has not yet been pushed by OneTrust, read the OptanonConsent cookie and return the consent groups from there.
4. If neither the dataLayer nor the cookie is available (visitor first visit when OneTrust hasn't yet loaded), return a possible fallback default value that has been entered in the template. Otherwise return an empty value.

Output options:
A comma joined string or a JS array.

New: Possibility to return the selected consent group's status as "true" or "false".

Usage:
Check if the variable value contains the desired group, for example "C0002:1". C0002 is the consent group and 1 means that consent for it has been granted.
