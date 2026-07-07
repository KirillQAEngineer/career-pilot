from app.schemas.resume_profile import ResumeProfile


class SearchQueryService:

    def build(
        self,
        profile: ResumeProfile,
    ) -> list[str]:

        queries = []

        queries.append(profile.profession)

        queries.extend(profile.preferred_roles)

        for skill in profile.skills:
            queries.append(
                f"{profile.profession} {skill}"
            )

        queries.append(
            f"{profile.level} {profile.profession}"
        )

        return list(dict.fromkeys(queries))