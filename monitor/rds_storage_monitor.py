#!/usr/bin/env python3
import boto3
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from datetime import datetime, timedelta
import numpy as np

class RDSStorageMonitor:
    def __init__(self, db_instance_id='rds-prod', region='us-east-1'):
        self.db_instance_id = db_instance_id
        self.cloudwatch = boto3.client('cloudwatch', region_name=region)
        self.fig, self.ax = plt.subplots(figsize=(12, 6))
        self.times = []
        self.free_storage = []
        
    def get_free_storage(self):
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(minutes=30)
        
        response = self.cloudwatch.get_metric_statistics(
            Namespace='AWS/RDS',
            MetricName='FreeStorageSpace',
            Dimensions=[{'Name': 'DBInstanceIdentifier', 'Value': self.db_instance_id}],
            StartTime=start_time,
            EndTime=end_time,
            Period=60,
            Statistics=['Average']
        )
        
        if response['Datapoints']:
            # Sort by timestamp
            datapoints = sorted(response['Datapoints'], key=lambda x: x['Timestamp'])
            return [(dp['Timestamp'], dp['Average'] / (1024**3)) for dp in datapoints]  # Convert to GB
        return []
    
    def update_plot(self, frame):
        data = self.get_free_storage()
        if data:
            self.times = [dp[0] for dp in data]
            self.free_storage = [dp[1] for dp in data]
            
            self.ax.clear()
            self.ax.plot(self.times, self.free_storage, 'b-', linewidth=2, marker='o', markersize=4)
            self.ax.set_title(f'RDS Free Storage Space - {self.db_instance_id}', fontsize=14, fontweight='bold')
            self.ax.set_xlabel('Time (UTC)')
            self.ax.set_ylabel('Free Storage (GB)')
            self.ax.grid(True, alpha=0.3)
            
            # Format x-axis
            self.ax.tick_params(axis='x', rotation=45)
            
            # Add current value annotation
            if self.free_storage:
                current_value = self.free_storage[-1]
                self.ax.annotate(f'{current_value:.2f} GB', 
                               xy=(self.times[-1], current_value),
                               xytext=(10, 10), textcoords='offset points',
                               bbox=dict(boxstyle='round,pad=0.3', facecolor='yellow', alpha=0.7),
                               fontsize=10, fontweight='bold')
        
        plt.tight_layout()
    
    def start_monitoring(self):
        ani = animation.FuncAnimation(self.fig, self.update_plot, interval=30000, cache_frame_data=False)
        plt.show()
        return ani

if __name__ == "__main__":
    monitor = RDSStorageMonitor()
    print("Starting RDS Storage Monitor...")
    print("Press Ctrl+C to stop")
    try:
        ani = monitor.start_monitoring()
        plt.show()
    except KeyboardInterrupt:
        print("\nMonitoring stopped.")
