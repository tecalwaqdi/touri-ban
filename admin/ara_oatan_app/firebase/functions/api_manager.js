/**
 * FlutterFlow private API dispatcher.
 *
 * All production integrations in this project are explicit callable
 * functions, so the generated private call map intentionally stays empty.
 */
async function makeApiCall(context, data) {
  const callName = data["callName"] || "";
  const callMap = {};

  if (!(callName in callMap)) {
    return {
      statusCode: 400,
      error: `API Call "${callName}" not defined as private API.`,
    };
  }

  return callMap[callName](context, data["variables"] || {});
}

module.exports = {makeApiCall};
