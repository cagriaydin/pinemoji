import 'dart:io';
import 'dart:typed_data';
import 'package:esys_flutter_share/esys_flutter_share.dart';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pinemoji/models/answer.dart';
import 'package:pinemoji/models/question_result.dart';
import 'package:pinemoji/models/result.dart';
import 'package:pinemoji/repositories/survey_repository.dart';
import 'package:pinemoji/widgets/header-widget.dart';
import 'package:pinemoji/widgets/outcome-button.dart';
import 'package:pinemoji/widgets/survey-card.dart';
import 'package:pinemoji/widgets/survey-filter-item.dart';

class SurveyResultPage extends StatefulWidget {
  @override
  _SurveyResultPageState createState() => _SurveyResultPageState();
}

class _SurveyResultPageState extends State<SurveyResultPage> {
  QuestionResult selectedQuestion;
  Result result;
  bool hasLoading = false;

  @override
  void initState() {
    SurveyRepository()
        .getSurveyResult()
        .then((value) => setState(() => result = value));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 20),
            child: Container(
              width: 200,
              child: HeaderWidget(
                title: "Anket Sonuçları",
                isDarkTeheme: true,
              ),
            ),
          ),
          hasLoading
              ? Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          backgroundColor: Colors.white70,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          "Sonuçlar Hazırlanıyor...",
                          style: TextStyle(
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                            fontSize: 24,
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : Container(
                  constraints: BoxConstraints(
                      maxHeight: selectedQuestion != null
                          ? MediaQuery.of(context).size.height * .34
                          : MediaQuery.of(context).size.height * .65),
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: EdgeInsets.fromLTRB(20, 40, 20, 20),
                    mainAxisSpacing: 40,
                    crossAxisSpacing: 10,
                    childAspectRatio: .7,
                    shrinkWrap: true,
                    children: [
                      if (result != null)
                        ...result.questionResultList.map((question) {
                          final GlobalKey _currentQuestionKey = GlobalKey();
                          return GestureDetector(
                            key: _currentQuestionKey,
                            onTap: () {
                              setState(() {
                                if (selectedQuestion == question) {
                                  selectedQuestion = null;
                                } else {
                                  selectedQuestion = question;
                                  Scrollable.ensureVisible(
                                    _currentQuestionKey.currentContext,
                                    curve: Curves.easeIn,
                                    duration: Duration(
                                      milliseconds: 300,
                                    ),
                                  );
                                }
                              });
                            },
                            child: SurveyCard(
                              selectedQuestion: selectedQuestion,
                              question: question,
                            ),
                          );
                        }).toList()
                    ],
                  ),
                ),
          if (selectedQuestion != null)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 20),
                    child: Container(
                      width: 180,
                      child: HeaderWidget(
                        title: "Sağlık Durumu",
                        isDarkTeheme: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          "Hastane",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "Sağlık Durumu",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "Doktor",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: groupByAnswer(selectedQuestion.answerList)
                              .map((answer) => SurveyFilterItem(
                                    surveyAnswer: answer,
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          if (selectedQuestion == null && !hasLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 7, 0, 0),
              child: OutcomeButton(
                text: "Sonuçları Paylaş",
                action: () {
                  createReport();
                },
              ),
            )
        ],
      ),
    );
  }

  List<Answer> groupByAnswer(List<Answer> answerList) {
    Map<String, Map<String, Answer>> resultMap = {};
    List<Answer> reslutList = [];
    answerList.forEach((answer) {
      if (resultMap[answer.answerText] == null) {
        resultMap[answer.answerText] = {};
      }
      answer.ownerList.forEach((owner, location) {
        if (resultMap[location] == null) {
          resultMap[answer.answerText][location] =
              answerFromJson(answerToJson(answer));
        }
      });
    });
    resultMap.forEach((ansT, map) {
      map.forEach((loca, answer) {
        answer.ownerList.removeWhere((owner, loc) => loc != loca);
        reslutList.add(answer);
      });
    });
    return reslutList;
  }

  createReport() async {
    setState(() {
      hasLoading = true;
    });
    var excel = Excel.createExcel();
    var sheet = excel.tables.keys.first;
    excel.insertRow(sheet, 0);
    excel.updateCell(
        sheet, CellIndex.indexByColumnRow(rowIndex: 0, columnIndex: 0), "Soru No",
        backgroundColorHex: "#263964", fontColorHex: "#C7CAD1");

    excel.updateCell(sheet,
        CellIndex.indexByColumnRow(rowIndex: 0, columnIndex: 1), "Anket Sorusu",
        backgroundColorHex: "#263964", fontColorHex: "#C7CAD1");

    excel.updateCell(
        sheet,
        CellIndex.indexByColumnRow(rowIndex: 0, columnIndex: 2),
        "Katılımcı Sayısı",
        backgroundColorHex: "#263964",
        fontColorHex: "#C7CAD1");

    excel.updateCell(sheet,
        CellIndex.indexByColumnRow(rowIndex: 0, columnIndex: 3), "Hastane Adı",
        backgroundColorHex: "#263964", fontColorHex: "#C7CAD1");

    excel.updateCell(
        sheet, CellIndex.indexByColumnRow(rowIndex: 0, columnIndex: 4), "Yanıt",
        backgroundColorHex: "#263964", fontColorHex: "#C7CAD1");

    excel.updateCell(
        sheet,
        CellIndex.indexByColumnRow(rowIndex: 0, columnIndex: 5),
        "Yanıtlayan Doktor Sayısı",
        backgroundColorHex: "#263964",
        fontColorHex: "#C7CAD1");

    int index = 0;
    for (QuestionResult res in result.questionResultList) {
      int startIndex = index + 1;
      int answerCount = 0;
      List<Answer> answerList = groupByAnswer(res.answerList);
      for (Answer answer in answerList) {
        index++;
        excel.insertRow(sheet, index);
        excel.updateCell(
            sheet,
            CellIndex.indexByColumnRow(rowIndex: index, columnIndex: 0),
            result.questionResultList.indexOf(res) + 1);
        excel.updateCell(
            sheet,
            CellIndex.indexByColumnRow(rowIndex: index, columnIndex: 1),
            res.questionText);
        excel.updateCell(
            sheet,
            CellIndex.indexByColumnRow(rowIndex: index, columnIndex: 3),
            answer.ownerList[answer.ownerList.keys.elementAt(0)]);
        excel.updateCell(
            sheet,
            CellIndex.indexByColumnRow(rowIndex: index, columnIndex: 4),
            answer.answerText);
        excel.updateCell(
            sheet,
            CellIndex.indexByColumnRow(rowIndex: index, columnIndex: 5),
            answer.ownerList.length);
        answerCount = answerCount + answer.ownerList.length;
      }
      for (int i = startIndex; i <= index; i++) {
        excel.updateCell(
            sheet,
            CellIndex.indexByColumnRow(rowIndex: i, columnIndex: 2),
            answerCount);
      }
    }

    final directory = await getApplicationDocumentsDirectory();
    var file = File(directory.path + "/AnketSonuclari.xlsx");
    file.writeAsBytesSync(await excel.encode());

    Uint8List readAsBytes = await file.readAsBytes();
    setState(() {
      hasLoading = false;
    });
    await Share.file(
      'excel file',
      'AnketSonuclari.xlsx',
      readAsBytes,
      '*/*',
    );
  }
}
