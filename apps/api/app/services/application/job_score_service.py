from app.schemas.job import Job


class JobScoreService:

    def score(self, resume_text: str, job: Job) -> float:

        resume = resume_text.lower()
        title = job.title.lower()

        score = 0

        # 1. совпадение по роли
        role_keywords = [
            "engineer",
            "developer",
            "backend",
            "frontend",
            "full stack",
            "data scientist",
            "python",
            "software",
        ]

        for kw in role_keywords:
            if kw in resume and kw in title:
                score += 40

        # 2. seniority
        seniority_map = {
            "junior": 10,
            "middle": 20,
            "mid": 20,
            "senior": 30,
            "lead": 35,
            "staff": 40,
        }

        for k, v in seniority_map.items():
            if k in title:
                score += v

        # 3. tech boost
        tech_keywords = [
            "python",
            "java",
            "golang",
            "react",
            "fastapi",
            "django",
            "aws",
            "docker",
        ]

        for kw in tech_keywords:
            if kw in resume and kw in title:
                score += 20

        # 4. spam penalty
        spam_keywords = [
            "casino",
            "tester",
            "adult",
            "escort",
            "crypto trader",
            "sales call",
        ]

        for kw in spam_keywords:
            if kw in title:
                score -= 50

        return max(score, 0)