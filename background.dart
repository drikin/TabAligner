import 'package:chrome/chrome_ext.dart' as chrome;

void main() {
  // Check if webNavigation API is available
  if (chrome.webNavigation.available) {

    // Setup alignTab feature
    chrome.webNavigation.onBeforeNavigate.listen((value) {
      alignTab(value, 'onBeforeNavigate');
    });
    chrome.webNavigation.onCompleted.listen((value) {
      alignTab(value, 'onCompleted');
    });

    // Setup browserAction
    chrome.browserAction.onClicked.listen((tab) {
      groupTabs();
    });
  }
}

void alignTab(tab, [String from]) {
    int currentTabId   = tab['tabId'];
    if (tab['frameId'] == 0 && currentTabId > 0) {
      //print('Called from ${from} tabID: ${currentTabId} frameId: ${tab['frameId']}');
      chrome.tabs.get(currentTabId).then((tab) {
        int windowId = tab.windowId;
        int tabIndex = tab.index;
        Uri tabUri    = Uri.parse(tab.url);

        chrome.TabsQueryParams q = new chrome.TabsQueryParams(windowId: windowId);
        chrome.tabs.query(q).then((tabs) {
          // exactly same url case
          tabs.forEach((target) {
            if (target.id != currentTabId) {
              Uri targetUri = Uri.parse(target.url);
              if (targetUri == tabUri) {
                print('detect duplicate');
                chrome.TabsUpdateParams q = new chrome.TabsUpdateParams(active: true);
                chrome.tabs.update(q, target.id);
                chrome.tabs.remove(currentTabId);
              }
            }
          });

          for (int i = tabs.length - 1; i >= 0; i--) {
            var target      = tabs[i];
            int targetId    = target.id;
            int targetIndex = target.index;
            if (targetId != currentTabId) {
              Uri targetUri = Uri.parse(target.url);
              //print('${tabUri} ${targetUri}');

              // same domain case
              if (targetUri.host == tabUri.host) {
                // check right tab
                int rightIndex = tabIndex + 1;
                if (rightIndex < tabs.length) {
                  var rightTab = tabs[tabIndex + 1];
                  Uri rightUri = Uri.parse(rightTab.url);
                  if (rightUri.host == tabUri.host) {
                    print('dont move');
                    break;
                  }
                }
                if (tabIndex < targetIndex) {
                  targetIndex--;
                }
                chrome.TabsMoveParams q = new chrome.TabsMoveParams(index: targetIndex + 1, windowId: windowId);
                chrome.tabs.move([currentTabId], q);
                print('aligned');
                break;
              }
            }
          }
        });
      });
    }
}

void groupTabs() {
  List<chrome.Tab> allTabs = [];

  chrome.WindowsGetAllParams q = new chrome.WindowsGetAllParams(populate: true);
  chrome.windows.getAll(q).then((windows) {
    // Gathering all tab informations
    windows.forEach((window) {
      List<chrome.Tab> tabs = window.tabs;
      tabs.forEach((tab) {
        allTabs.add(tab);
      });
    });

    if (allTabs.length > 1) {
      // Generate new window set
      var newTabs = [];
      var singles = [];
      while(allTabs.length > 0) {
        var t = allTabs.removeAt(0);
        Uri url = Uri.parse(t.url);
        var tabs = allTabs.where((f) => f.url.contains(url.host)).toList();
        if (tabs.length > 0) {
          tabs.forEach((tab) {
            allTabs.remove(tab);
          });
          tabs.insert(0, t);
          newTabs.add(tabs);
        } else {
          singles.add(t);
        }
      }
      newTabs.add(singles);

      // Create new windows
      newTabs.forEach((tabs) {
        var firstTab = tabs.removeAt(0);
        chrome.WindowsCreateParams createData = new chrome.WindowsCreateParams(focused:true, type:"normal", tabId:firstTab.id);
        chrome.windows.create(createData).then((window) {
          chrome.TabsMoveParams moveProperties = new chrome.TabsMoveParams(index:-1, windowId:window.id);
          List tabIds = tabs.map((t) => t.id).toList();
          chrome.tabs.move(tabIds, moveProperties);
        });;
      });
    }
  });
}

