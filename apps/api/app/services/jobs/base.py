from abc import ABC, abstractmethod


class JobProvider(ABC):

    @abstractmethod
    def search(self, query: str) -> list[dict]:
        pass