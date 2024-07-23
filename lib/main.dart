import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vagijbhipymkdleztnqe.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZhZ2lqYmhpcHlta2RsZXp0bnFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjEyOTUyMjcsImV4cCI6MjAzNjg3MTIyN30.9fstCfOubvNP5ly0jJMPGYmY-kye6AIiby84Swhln2U',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Supabase Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final formKey = GlobalKey<FormState>();
  final supabaseClient = Supabase.instance.client;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController educationController = TextEditingController();
  final TextEditingController maritalStatusController = TextEditingController();
  final TextEditingController housingController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  Future<void> _insertUser() async {
    try {
      final response = await supabaseClient.from('users').insert({
        'email': emailController.text,
        'password': passwordController.text,
        'name': nameController.text,
        'education': educationController.text,
        'marital_status': maritalStatusController.text,
        'housing': housingController.text,
        'age': double.tryParse(ageController.text),
        'salary': double.tryParse(salaryController.text),
      });
      print('Response: $response');

      if (response.error != null) {
        print('Error inserting user: ${response.error!.message}');
      } else {
        print('User inserted successfully');
        await _fetchCategoriesAndQuestions(); // Fetch categories and questions after user insertion
      }
    } catch (e) {
      print('Exception in _insertUser: $e');
    }
  }

  Future<void> _fetchCategoriesAndQuestions() async {
    try {
      final userResponse = await supabaseClient
          .from('users')
          .select('id, age') 
          .eq('email', emailController.text)
          .single();

      final userId = userResponse['id'];
      final userAge = userResponse['age'] as double;

      // استعلام للحصول على تصنيفات المستخدم
      final userCategoriesResponse = await supabaseClient
          .from('user_categories')
          .select('category_id')
          .eq('user_id', userId);

      final categoryIds = (userCategoriesResponse as List<dynamic>)
          .map((row) => row['category_id'] as String)
          .toList();

      // استعلام للحصول على الأسئلة بناءً على التصنيفات
      final questionsResponse = await supabaseClient
          .from('questions')
          .select('id, question_text, category_id')
          .contains('category_id', categoryIds);

      final allQuestions = (questionsResponse as List<dynamic>)
          .map((row) => {
                'question_text': row['question_text'] as String,
                'id': row['id'] as String,
              })
          .toList();

      List<Map<String, dynamic>> selectedQuestions;

      // تحديد عدد الأسئلة بناءً على العمر
      if (userAge < 20) {
        selectedQuestions = allQuestions; // جميع الأسئلة
      } else if (userAge < 40) {
        selectedQuestions = allQuestions.take(5).toList(); // 5 أسئلة
      } else if (userAge > 50) {
        selectedQuestions = allQuestions.take(2).toList(); // 2 أسئلة
      } else {
        selectedQuestions = allQuestions; // جميع الأسئلة
      }

      // استعلام للحصول على الأجوبة لكل سؤال
      final answersResponse =
          await Future.wait(selectedQuestions.map((question) async {
        final answers = await supabaseClient
            .from('answers')
            .select('answer_text')
            .eq('question_id', question['id']);
        return {
          'question': question,
          'answers': (answers as List<dynamic>)
              .map((row) => row['answer_text'] as String)
              .toList(),
        };
      }));

      // الانتقال إلى شاشة الأسئلة مع الأسئلة والإجوبة
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              QuestionsScreen(questionsWithAnswers: answersResponse),
        ),
      );
    } catch (e) {
      print('Exception in _fetchCategoriesAndQuestions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Supabase Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: educationController,
                decoration: const InputDecoration(labelText: 'Education'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your education';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: maritalStatusController,
                decoration: const InputDecoration(labelText: 'Marital Status'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your marital status';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: housingController,
                decoration: const InputDecoration(labelText: 'Housing'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your housing';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: salaryController,
                decoration: const InputDecoration(labelText: 'Salary'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your salary';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    _insertUser();
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuestionsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> questionsWithAnswers;

  QuestionsScreen({required this.questionsWithAnswers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questions'),
      ),
      body: ListView.builder(
        itemCount: questionsWithAnswers.length,
        itemBuilder: (context, index) {
          final questionWithAnswers = questionsWithAnswers[index];
          final questionText = questionWithAnswers['question']['question_text'];
          final answers = questionWithAnswers['answers'] as List<String>;

          return ExpansionTile(
            title: Text(questionText),
            children:
                answers.map((answer) => ListTile(title: Text(answer))).toList(),
          );
        },
      ),
    );
  }
}
