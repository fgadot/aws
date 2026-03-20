import boto3
import os
import sys
import shutil

# Initialize EC2 client
ec2 = boto3.client('ec2')

USE_COLOR = sys.stdout.isatty() and os.environ.get("NO_COLOR") is None

def zebra(line: str, row_num: int) -> str:
    """Alternate dark/light background per row (only when printing to a TTY)."""
    if not USE_COLOR:
        return line

    term_width = shutil.get_terminal_size((120, 20)).columns
    line = line.ljust(term_width)

    # odd/even background shades
    bg = "48;5;236" if (row_num % 2) else "48;5;238"   # dark / slightly lighter
    fg = "38;5;255"                                    # white text
    return f"\033[{bg};{fg}m{line}\033[0m"


def list_instances():
    """Fetch and list EC2 instances in a formatted way."""
    response = ec2.describe_instances()
    instances = []

    print("\n===================================================================")
    print(" EC2 Instances:")
    print("===================================================================")
    print(f"{'No.':<4} {'Instance ID':<20} {'State':<12} {'Private IP':<15} {'Name'}")
    print("-------------------------------------------------------------------")

    index = 1
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            state = instance['State']['Name']
            private_ip = instance.get('PrivateIpAddress', 'N/A')

            # Extract instance name tag if it exists
            name = "No Name"
            if 'Tags' in instance:
                for tag in instance['Tags']:
                    if tag['Key'] == 'Name':
                        name = tag['Value']
                        break

            instances.append((index, instance_id, state, private_ip, name))

            row = f"{index:<4} {instance_id:<20} {state:<12} {private_ip:<15} {name}"
            print(zebra(row, index))
            index += 1

    print("===================================================================")
    return instances


def select_instance(instances, action):
    """Allow user to select an instance by number for an action."""
    if not instances:
        print("No instances available.")
        return None

    try:
        selection = int(input(f"Enter the number of the instance to {action}: "))
        for item in instances:
            if item[0] == selection:
                return item[1]  # Return Instance ID
    except ValueError:
        pass

    print("Invalid selection. Please enter a valid number.")
    return None


def start_instance():
    """Start a selected EC2 instance."""
    instances = list_instances()
    instance_id = select_instance(instances, "start")

    if instance_id:
        ec2.start_instances(InstanceIds=[instance_id])
        print(f"Instance {instance_id} is starting...")


def stop_instance():
    """Stop a selected EC2 instance."""
    instances = list_instances()
    instance_id = select_instance(instances, "stop")

    if instance_id:
        ec2.stop_instances(InstanceIds=[instance_id])
        print(f"Instance {instance_id} is stopping...")


def main():
    """Main menu for EC2 instance management."""
    while True:
        print("\n=============================")
        print("EC2 Instance Manager")
        print("=============================")
        print("1. List EC2 Instances")
        print("2. Start an EC2 Instance")
        print("3. Stop an EC2 Instance")
        print("4. Exit")
        print("=============================")

        choice = input("Choose an option: ")

        if choice == "1":
            list_instances()
        elif choice == "2":
            start_instance()
        elif choice == "3":
            stop_instance()
        elif choice == "4":
            print("Exiting...")
            break
        else:
            print("Invalid option. Please try again.")


if __name__ == "__main__":
    main()

