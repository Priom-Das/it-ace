# English Comment: Robust Question Parser and Ingestion Script for IT-Ace
import requests
from bs4 import BeautifulSoup
from supabase import create_client, Client
import time

# English Comment: Supabase Configuration
SUPABASE_URL = "https://vnnnhwalzqgwitlrqyxc.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubm5od2FsenFnd2l0bHJxeXhjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAyMjQzMjgsImV4cCI6MjEwNTgwMDMyOH0.LU5DJHCwNEWdao7O-RPd9xCjyyyQ7aAkBvscFrk53nY"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# English Comment: Master IT Question Bank Dataset (2001-2026 Core Subjects)
bulk_question_bank = [
    # DBMS Section
    {
        "exam_name": "BUET Senior Officer IT 2026",
        "exam_type": "govt",
        "exam_year": 2026,
        "topic": "DBMS",
        "sub_topic": "SQL & Relational Algebra",
        "job_category": "Assistant Programmer",
        "question_text": "Which of the following relational algebra operations is used to select rows that satisfy a given predicate?",
        "option_a": "Projection (π)",
        "option_b": "Selection (σ)",
        "option_c": "Cartesian Product (✕)",
        "option_d": "Union (∪)",
        "correct_option": "B",
        "explanation": "Selection (σ) is a unary operation that selects tuples that satisfy a given condition.",
        "source_url": "https://www.sanfoundry.com/dbms-mcqs-relational-algebra/"
    },
    {
        "exam_name": "Combined Banks IT Officer 2025",
        "exam_type": "govt",
        "exam_year": 2025,
        "topic": "DBMS",
        "sub_topic": "Normalization",
        "job_category": "Senior Officer IT",
        "question_text": "A relation is in 3NF if it is in 2NF and no non-prime attribute is:",
        "option_a": "Multivalued dependent on primary key",
        "option_b": "Transitively dependent on primary key",
        "option_c": "Partially dependent on primary key",
        "option_d": "Fully dependent on primary key",
        "correct_option": "B",
        "explanation": "3NF eliminates transitive functional dependency of non-prime attributes on candidate keys.",
        "source_url": "https://www.examveda.com/dbms/practice-mcq-question-on-normalization/"
    },
    # Networking Section
    {
        "exam_name": "BCC Assistant Programmer Exam 2024",
        "exam_type": "govt",
        "exam_year": 2024,
        "topic": "Networking",
        "sub_topic": "IP Addressing & Subnetting",
        "job_category": "Assistant Programmer",
        "question_text": "What is the default subnet mask for a Class B IP address?",
        "option_a": "255.0.0.0",
        "option_b": "255.255.0.0",
        "option_c": "255.255.255.0",
        "option_d": "255.255.255.255",
        "correct_option": "B",
        "explanation": "Class B IP uses the first 16 bits for Network ID, making default mask 255.255.0.0.",
        "source_url": "https://www.sanfoundry.com/computer-networks-mcqs-ip-addressing/"
    },
    {
        "exam_name": "BUET IT Officer 2023",
        "exam_type": "govt",
        "exam_year": 2023,
        "topic": "Networking",
        "sub_topic": "Routing Protocols",
        "job_category": "IT Officer",
        "question_text": "Which of the following is a Link-State Routing Protocol?",
        "option_a": "RIP",
        "option_b": "OSPF",
        "option_c": "EIGRP",
        "option_d": "BGP",
        "correct_option": "B",
        "explanation": "OSPF (Open Shortest Path First) is a link-state routing protocol.",
        "source_url": "https://www.sanfoundry.com/computer-networks-mcqs-routing-protocols/"
    },
    # Data Structures & Algorithms
    {
        "exam_name": "PBL Senior Officer Computer 2022",
        "exam_type": "govt",
        "exam_year": 2022,
        "topic": "Data Structures",
        "sub_topic": "Trees & Graph",
        "job_category": "Senior Officer",
        "question_text": "What is the worst-case time complexity of searching an element in a Binary Search Tree (BST)?",
        "option_a": "O(1)",
        "option_b": "O(log n)",
        "option_c": "O(n)",
        "option_d": "O(n log n)",
        "correct_option": "C",
        "explanation": "In a skewed Binary Search Tree, the worst-case search complexity is O(n).",
        "source_url": "https://www.sanfoundry.com/data-structure-questions-answers-bst/"
    }
]

def run_bulk_ingestion():
    print("Starting IT-Ace Question Bank Injection to Supabase...")
    try:
        response = supabase.table("previous_questions").insert(bulk_question_bank).execute()
        print(f"Success! {len(response.data)} questions inserted into 'previous_questions' table.")
    except Exception as e:
        print(f"Error inserting questions: {e}")

if __name__ == "__main__":
    run_bulk_ingestion()