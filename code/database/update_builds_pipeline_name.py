from pymongo import MongoClient
import os

MONGODB_URI = os.environ.get('MONGODB_URI', 'mongodb://admin:password123@localhost:27017/cicd-dashboard?authSource=admin')
client = MongoClient(MONGODB_URI)
db = client.get_database()

# Update all builds to ensure pipeline_name is present and correct
for build in db.builds.find():
    pipeline_name = build.get('pipeline_name')
    build_number = build.get('build_number') or build.get('number')
    # If missing, try to infer from context or set manually
    if not pipeline_name:
        # If you know the job name, set it here. Otherwise, skip or log.
        # Example: pipeline_name = 'Sample-Test-Two'
        continue
    db.builds.update_one(
        {'_id': build['_id']},
        {'$set': {'pipeline_name': pipeline_name, 'build_number': build_number}}
    )
print('Build records updated with pipeline_name and build_number.')
