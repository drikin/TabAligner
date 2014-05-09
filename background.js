// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/**
 * @filedescription Initializes the extension's background page.
 */
var eventList = ['onBeforeNavigate', 'onCompleted'];

// init
eventList.forEach(function(e) {
  chrome.webNavigation[e].addListener(function(data) {
    alignTab(data);
  });
});

var parser = document.createElement('a');

function getHostName(urlStr) {
  parser.href = urlStr;
  return parser.hostname;
}

function alignTab(data) {
  if(typeof data && data.frameId === 0) {
    if (data&&data.url) {
      console.log(data, data.url);
      var loadingHost = getHostName(data.url);
      var loadingTabId = data.tabId;

      //console.log(loadingTabId);
      if (!loadingTabId) {
        return;
      }
      // get windowId from tabId
      chrome.tabs.get(loadingTabId, function(tab) {
        if (!tab) return;

        //console.log(tab);
        var loadingTabIndex = tab.index;

        // find tareget position
        chrome.tabs.query({windowId: tab.windowId}, function(tabs){
          if (!tabs) return;

          //console.log(tabs);
          for(var i = tabs.length - 1; i >= 0; i--) {
            var targetTab = tabs[i];
            var targetTabId = targetTab.id;
            if (targetTabId !== loadingTabId) {
              var tabHost = getHostName(targetTab.url);
              if (loadingHost === tabHost) {
                var targetTabIndex = targetTab.index;
                if (loadingTabIndex < targetTabIndex) {
                  targetTabIndex--;
                }
                chrome.tabs.move(loadingTabId, {index: targetTabIndex + 1});
                break;
              }
            }
          }
        });
      });
    }
  }
}
// vim: tabstop=2 shiftwidth=2 textwidth=0 expandtab foldmethod=marker nowrap
