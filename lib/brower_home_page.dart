import 'package:flutter/material.dart';
import 'browser_service.dart';

class BrowserHomePage extends StatefulWidget {
  @override
  _BrowserHomePageState createState() => _BrowserHomePageState();
}

class _BrowserHomePageState extends State<BrowserHomePage> {
  final List<WebTab> _tabs = [];
  int _currentTabIndex = 0;

  final TextEditingController _urlController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _openNewTab(String url) {
    setState(() {
      _tabs.add(WebTab(url: url));
      _currentTabIndex = _tabs.length - 1;
    });
  }

  void _closeTab(int index) {
    setState(() {
      _tabs.removeAt(index);
      if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.length - 1;
      }
    });
  }

  void _refreshPage(int index) {
    setState(() {
      _tabs[index].key.currentState!.reload();
    });
  }

  void _launchURL(String url) async {
    if (!await canLaunch(url)) {
      !await _launch(url);
    } else {
      // Handle error if any
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Browser'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _openNewTab('');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'Enter URL',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _openNewTab(_urlController.text);
                      _urlController.clear();
                    }
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a URL';
                }
                return null;
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    _tabs[index].url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: () {
                          _refreshPage(index);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          _closeTab(index);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _currentTabIndex = index;
                    });
                  },
                );
              },
            ),
          ),
          Expanded(
            flex: 5,
            child: IndexedStack(
              index: _currentTabIndex,
              children: _tabs.map((tab) {
                return WebViewPage(key: tab.key, url: tab.url);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}