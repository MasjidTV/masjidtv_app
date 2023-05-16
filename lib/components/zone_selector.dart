import 'package:flutter/material.dart';

import '../model/jakim_zones.dart';

class ZoneSelector extends StatefulWidget {
  const ZoneSelector({super.key, required this.jakimZones});

  final List<JakimZones> jakimZones;

  @override
  State<ZoneSelector> createState() => _ZoneSelectorState();
}

class _ZoneSelectorState extends State<ZoneSelector> {
  late final List<String> negeriList;
  List<JakimZones> jakimZonesInSelectedNegeri = [];
  String? selectedNegeri;
  JakimZones? selectedJakimZone;

  @override
  void initState() {
    super.initState();
    negeriList = widget.jakimZones.map((e) => e.negeri).toSet().toList();
    debugPrint(negeriList.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select zones'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, selectedJakimZone);
            },
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 28),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: negeriList.length,
              itemBuilder: (_, index) {
                return ListTile(
                  title: Text(
                    negeriList[index],
                  ),
                  onTap: () {
                    setState(() {
                      selectedNegeri = negeriList[index];
                      jakimZonesInSelectedNegeri = widget.jakimZones
                          .where((e) => e.negeri == negeriList[index])
                          .toList();
                    });
                  },
                  titleTextStyle: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(fontSize: 22),
                  selected: negeriList[index] == selectedNegeri,
                  selectedTileColor:
                      Theme.of(context).colorScheme.primaryContainer,
                );
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Card(
              clipBehavior: Clip.hardEdge,
              child: ListView.builder(
                itemCount: jakimZonesInSelectedNegeri.length,
                itemBuilder: (_, index) {
                  return ListTile(
                    title: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text:
                                '[${jakimZonesInSelectedNegeri[index].jakimCode}] ',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(
                            text: jakimZonesInSelectedNegeri[index].daerah),
                      ]),
                    ),
                    onTap: () {
                      setState(() {
                        selectedJakimZone = jakimZonesInSelectedNegeri[index];
                      });
                    },
                    titleTextStyle: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(fontSize: 22),
                    selected:
                        selectedJakimZone == jakimZonesInSelectedNegeri[index],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
