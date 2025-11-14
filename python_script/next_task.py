import sys

def get_next_task():
    """
    Prompts the user for the next task and prints it to stdout.
    """
    print("\n" + "="*120)
    print("Please describe the next task you'd like me to work on.")
    print("You can also type 'exit' or 'quit' to end the session.")
    print("="*120)
    
    try:
        task_description = input("> ")
    except KeyboardInterrupt:
        print("\nSession ended by user.")
        sys.exit(0)
    
    if task_description.lower().strip() in ['exit', 'quit']:
        print("Session ended. Goodbye!")
        sys.exit(0)
        
    print("\nReceived next task:")
    print(f'  "{task_description}"')
    print("\nThank you, I will get to work on that now.")

if __name__ == "__main__":
    get_next_task()
