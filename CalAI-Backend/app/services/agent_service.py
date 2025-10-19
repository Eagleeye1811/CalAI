from typing import List
from pydantic_ai.models.gemini import GeminiModel
from pydantic_ai import Agent
from app.config.chat_config import chat_config
from app.tools.agent_tools import create_agent_tools
import logfire
import os

logfire.configure()
# logfire.instrument_pydantic_ai()


class UserContext:
    """Context class to store user-specific information."""

    def __init__(
        self,
        dietary_preferences: List[str] = None,
        allergies: List[str] = None,
        selected_goals: List[str] = None,
    ):
        self.dietary_preferences = dietary_preferences or []
        self.allergies = allergies or []
        self.selected_goals = selected_goals or []


class AgentService:
    # GeminiModel reads API key from GOOGLE_API_KEY or GEMINI_API_KEY environment variable
    # Set the environment variable before creating the model
    if chat_config.gemini_api_key:
        os.environ['GEMINI_API_KEY'] = chat_config.gemini_api_key
    
    model = GeminiModel(chat_config.model_name)

    @staticmethod
    def create_chat_agent(
        dietaryPreferences: List[str],
        allergies: List[str],
        selectedGoals: List[str],
    ):
        """Create and return a chat agent instance with user context."""

        # Format system prompt with user preferences
        formatted_system_prompt = chat_config.system_prompt.format(
            dietaryPreferences=(
                ", ".join(dietaryPreferences) if dietaryPreferences else "none"
            ),
            allergies=", ".join(allergies) if allergies else "none",
            selectedGoals=", ".join(selectedGoals) if selectedGoals else "none",
        )

        # Create new agent instance
        agent = Agent(
            model=AgentService.model,
            system_prompt=formatted_system_prompt,
        )

        # Create user context
        user_context = UserContext(
            dietary_preferences=dietaryPreferences,
            allergies=allergies,
            selected_goals=selectedGoals,
        )

        # Register tools with the agent and user context
        create_agent_tools(agent, user_context)

        return agent